import os
import tempfile
import traceback
from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, auth, firestore
import json

# Load environment variables from .env file securely
load_dotenv()
import uvicorn

import analyzer
import llm_service

# Initialize Firebase Admin
_firebase_init_source = "none"
try:
    if not firebase_admin._apps:
        service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
        if service_account_json:
            # Render/Production: Load from environment variable
            cred_dict = json.loads(service_account_json)
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            _firebase_init_source = "env_var:FIREBASE_SERVICE_ACCOUNT_JSON"
            print(f"[Firebase] Initialized via environment variable. Project: {cred_dict.get('project_id', 'unknown')}")
        else:
            # Local: Try to load from local file if it exists, otherwise default
            local_key = "service-account.json"
            if os.path.exists(local_key):
                cred = credentials.Certificate(local_key)
                firebase_admin.initialize_app(cred)
                _firebase_init_source = f"local_file:{local_key}"
                print(f"[Firebase] Initialized via {local_key}.")
            else:
                firebase_admin.initialize_app()
                _firebase_init_source = "default_credentials"
                print("[Firebase] WARNING: Initialized via DEFAULT credentials.")
                print("[Firebase] WARNING: Default credentials CANNOT verify user ID tokens.")
                print("[Firebase] WARNING: All auth.verify_id_token() calls will fail with 401.")
                print("[Firebase] WARNING: Set FIREBASE_SERVICE_ACCOUNT_JSON in Render env vars to fix.")
    else:
        _firebase_init_source = "already_initialized"
    
    db = firestore.client()
    print(f"[Firebase] Firestore client ready. Init source: {_firebase_init_source}")
except Exception as e:
    print(f"[Firebase] ERROR: Failed to initialize Firebase Admin: {e}")
    print(f"[Firebase] ERROR: type={type(e).__name__}")
    db = None

def get_current_user(authorization: str = Header(None)):
    # ── DEVELOPMENT BYPASS ──────────────────────────────────────────────────
    # If we are in local dev (no service account), bypass token verification.
    if _firebase_init_source == "default_credentials":
        print("DEBUG: [Auth] LOCAL DEV BYPASS: Returning mock dev_user.")
        return {"uid": "dev_user", "email": "dev@smartsurf.ai"}
    # ────────────────────────────────────────────────────────────────────────
    
    if not authorization or not authorization.startswith("Bearer "):
        print("DEBUG: [Auth] FAILED: Missing or invalid Authorization header")
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    token = authorization.split("Bearer ")[1]
    
    try:
        decoded_token = auth.verify_id_token(token)
        print(f"DEBUG: [Auth] SUCCESS: Verified uid={decoded_token.get('uid')}")
        return decoded_token
    except Exception as e:
        error_type = type(e).__name__
        print(f"DEBUG: [Auth] ERROR: Token verification FAILED: {error_type}: {e}")
        
        # SECURITY: Only allow the bypass in non-production environments.
        # Ensure you set ENVIRONMENT=production in your Render/Production env vars.
        env = os.getenv("ENVIRONMENT", "development").lower()
        is_dev_env = env != "production"
        
        is_init_broken = _firebase_init_source in ["default_credentials", "already_initialized", "none"]
        
        if is_dev_env and (is_init_broken or error_type == "ValueError"):
            print(f"DEBUG: [Auth] BYPASS TRIGGERED: env={env}, type={error_type}, source={_firebase_init_source}. Using dev_user.")
            return {"uid": "dev_user", "email": "dev@smartsurf.ai"}
            
        raise HTTPException(status_code=401, detail=f"Token verification failed: {error_type}")

def get_existing_insight(uid: str, session_id: str):
    """Checks if a session already has a COMPLETE AI insight and returns it if it does."""
    if not db or not session_id:
        print("DEBUG: [Firestore] Skip existing check (no DB client)")
        return None
    
    try:
        session_ref = db.collection('users').document(uid).collection('sessions').document(session_id)
        doc = session_ref.get()
        if doc.exists:
            data = doc.to_dict()
            # We ONLY return existing if the primary insight fields are populated and non-empty.
            # This prevents returning a "stuck" session with null AI fields.
            required = ['aiSummaryEn', 'aiProgressPatternEn', 'aiNextFocusEn']
            is_complete = all(str(data.get(k) or "").strip() not in ["", "null", "None"] for k in required)
            
            if is_complete:
                print(f"BACKEND_AI_FIX_VERSION: ai_fields_guard_v3 (Existing Complete)")
                print(f"DEBUG: [Limit] Found VALID COMPLETE insight for session {session_id}")
                res = data.copy()
                res['BACKEND_AI_FIX_VERSION'] = 'ai_fields_guard_v3'
                return res
            else:
                # Check legacy keys too
                legacy = ['session_insight_en', 'progress_pattern_en', 'next_session_focus_en']
                is_legacy_complete = all(str(data.get(k) or "").strip() not in ["", "null", "None"] for k in legacy)
                if is_legacy_complete:
                    print(f"BACKEND_AI_FIX_VERSION: ai_fields_guard_v3 (Existing Legacy)")
                    print(f"DEBUG: [Limit] Found VALID LEGACY insight for session {session_id}")
                    res = data.copy()
                    res['BACKEND_AI_FIX_VERSION'] = 'ai_fields_guard_v3'
                    return res
                
                print(f"DEBUG: [Limit] Session {session_id} exists but insight is INCOMPLETE or NULL. Forcing fresh generation.")
    except Exception as e:
        print(f"Error checking existing insight: {e}")
    return None

def check_daily_limit(uid: str):
    """
    Checks if the user has reached their daily limit of 3 AI insights.
    Also enforces free-tier gating (1 free insight ever for non-pro).
    Returns the current count.
    """
    if not db: return 0
    from datetime import datetime, timezone
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    
    print(f"--- [LimitCheck Debug] uid={uid} ---")
    
    user_ref = db.collection('users').document(uid)
    doc = user_ref.get()
    
    is_pro = False
    used_first_free = False
    if doc.exists:
        data = doc.to_dict()
        is_pro = data.get('isSurferPro', False)
        used_first_free = data.get('hasUsedFirstFreeAIInsight', False)
        last_date = data.get('lastAiInsightDate')
        count = 0
        if last_date == today_str:
            count = data.get('aiInsightsTodayCount', 0)
            
        print(f"[LimitCheck] isPro: {is_pro}")
        print(f"[LimitCheck] usedFirstFree: {used_first_free}")
        print(f"[LimitCheck] Daily Count: {count}/3")
        
        # 1. Free-Tier Gate
        if not is_pro and used_first_free:
            print(f"[LimitCheck] BLOCKED: Free user already used their free insight.")
            raise HTTPException(
                status_code=403, 
                detail={
                    "error": "paywall_required",
                    "message": "You've used your one free insight. Upgrade to Surfer Pro for unlimited insights!"
                }
            )

        # 2. Daily Limit Gate (for everyone)
        if count >= 3:
            print(f"[LimitCheck] BLOCKED: Daily limit reached (3/3).")
            raise HTTPException(
                status_code=429, 
                detail={
                    "error": "daily_limit_reached",
                    "message": "Daily insight limit reached. You can generate up to 3 insights per day."
                }
            )
        
        return count
        
    print(f"[LimitCheck] Allowed: New user or first time today.")
    return 0

def increment_daily_limit(uid: str):
    """
    Increments the AI insight count for today. 
    Called ONLY after a successful generation and save.
    """
    if not db: return
    from datetime import datetime, timezone
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    
    user_ref = db.collection('users').document(uid)
    
    def do_increment(transaction):
        snapshot = user_ref.get(transaction=transaction)
        count = 0
        if snapshot.exists:
            data = snapshot.to_dict()
            if data.get('lastAiInsightDate') == today_str:
                count = data.get('aiInsightsTodayCount', 0)
        
        new_count = count + 1
        transaction.set(user_ref, {
            'aiInsightsTodayCount': new_count,
            'lastAiInsightDate': today_str,
            'hasUsedFirstFreeAIInsight': True, # Mark that they've used at least one
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        return new_count

    try:
        new_val = db.run_transaction(do_increment)
        print(f"DEBUG: [LimitIncrement] Success. New count: {new_val}/3 for {uid}")
    except Exception as e:
        print(f"DEBUG: [LimitIncrement] ERROR: {e}")

def record_insight_in_session(uid: str, session_id: str, insight_data: dict):
    """Records the generated insight in the session document."""
    if not db or not session_id: return
    user_ref = db.collection('users').document(uid)
    session_ref = user_ref.collection('sessions').document(session_id)
    session_ref.set({
        **insight_data,
        'updatedAt': firestore.SERVER_TIMESTAMP
    }, merge=True)

app = FastAPI(title="Smart Surf Pop-up Analyzer API")

# Allow requests from the Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict to allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "Smart Surf Pop-up Analyzer",
        "deploy": "594f965",
    }

@app.get("/api/firebase_status")
def firebase_status():
    """Public diagnostic endpoint — no auth required.
    Shows whether Firebase Admin is correctly initialized for token verification."""
    env_var_set = bool(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"))
    project_id = None
    if env_var_set:
        try:
            cred_dict = json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"))
            project_id = cred_dict.get("project_id", "parse_failed")
        except Exception:
            project_id = "json_parse_error"

    return {
        "firebase_init_source": _firebase_init_source,
        "env_var_FIREBASE_SERVICE_ACCOUNT_JSON_set": env_var_set,
        "project_id_from_env_var": project_id,
        "firestore_client_ready": db is not None,
        "token_verification_will_work": _firebase_init_source in (
            "env_var:FIREBASE_SERVICE_ACCOUNT_JSON",
            "local_file:service-account.json",
        ),
        "fix_needed": _firebase_init_source == "default_credentials",
        "fix_instructions": (
            "Set FIREBASE_SERVICE_ACCOUNT_JSON in Render environment variables "
            "with the full contents of your service-account.json file."
            if _firebase_init_source == "default_credentials" else None
        ),
    }

@app.get("/api/debug_prompt")
def debug_prompt():
    """Returns the exact system prompt and model config — no OpenAI call made.
    Use this to verify what prompt is live on Render."""
    import hashlib
    prompt_hash = hashlib.md5(llm_service.SYSTEM_PROMPT.encode()).hexdigest()
    return {
        "model": "gpt-4o-mini",
        "temperature": 0.4,
        "prompt_hash": prompt_hash,
        "prompt_char_count": len(llm_service.SYSTEM_PROMPT),
        "system_prompt": llm_service.SYSTEM_PROMPT.strip(),
    }

# Dedicated model for Surfer Pro Reflections
class ReflectionRequest(BaseModel):
    focus: str = ""
    worked_on: str = ""
    felt_hard: str = ""
    felt_good: str = ""
    conditions: str = ""
    notes: str = ""
    language: str = "en"
    session_id: str = "" # Used for per-session limit enforcement
    wave_height: str = ""
    board: str = ""

@app.post("/api/analyze_reflection")
async def analyze_reflection(
    request: ReflectionRequest,
    force_refresh: bool = False,
    current_user: dict = Depends(get_current_user)
):
    uid = current_user['uid']
    print(f"[Auth] analyze_reflection for uid={uid}")

    try:
        # 1. Per-session check: return existing if it was already generated
        if request.session_id:
            existing = get_existing_insight(uid, request.session_id)
            if existing and not force_refresh:
                print(f"[Limit] Returning existing insight for session {request.session_id}")
                print(f"FINAL aiSummaryEn = {existing.get('aiSummaryEn')}")
                print(f"FINAL aiProgressPatternEn = {existing.get('aiProgressPatternEn')}")
                print(f"FINAL aiNextFocusEn = {existing.get('aiNextFocusEn')}")
                print(f"FINAL aiFocusTagEn = {existing.get('aiFocusTagEn')}")
                return existing

        # 2. Daily limit check: block if 3/3
        check_daily_limit(uid)

        # 3. Fetch recent session history
        history = []
        if db:
            try:
                sessions_query = db.collection('users').document(uid).collection('sessions')\
                    .order_by('createdAt', direction=firestore.Query.DESCENDING)\
                    .limit(3).get()
                for doc in sessions_query:
                    history.append(doc.to_dict())
                print(f"[History] Loaded {len(history)} recent sessions")
            except Exception as e:
                print(f"[History] Could not fetch session history (non-fatal): {e}")

        # 4. Call the LLM
        print(f"[LLM] Calling generate_reflection — focus={request.focus!r}, felt_hard={request.felt_hard!r}")
        llm_result = llm_service.generate_reflection(
            focus=request.focus,
            worked_on=request.worked_on,
            felt_hard=request.felt_hard,
            felt_good=request.felt_good,
            conditions=request.conditions,
            notes=request.notes,
            language=request.language,
            history=history,
            wave_height=request.wave_height,
            board=request.board
        )
        
        # 5. COMPATIBILITY MAPPING & AUDIT
        final_payload = {
            'BACKEND_AI_FIX_VERSION': 'ai_fields_guard_v3',
            # New Keys (Requested)
            'aiSummaryEn': llm_result.get('aiSummaryEn'),
            'aiProgressPatternEn': llm_result.get('aiProgressPatternEn'),
            'aiNextFocusEn': llm_result.get('aiNextFocusEn'),
            'aiFocusTagEn': llm_result.get('aiFocusTagEn'),
            'aiSummaryEs': llm_result.get('aiSummaryEs'),
            'aiProgressPatternEs': llm_result.get('aiProgressPatternEs'),
            'aiNextFocusEs': llm_result.get('aiNextFocusEs'),
            'aiFocusTagEs': llm_result.get('aiFocusTagEs'),
            
            # Old Keys (Frontend Compatibility)
            'session_insight_en': llm_result.get('aiSummaryEn'),
            'progress_pattern_en': llm_result.get('aiProgressPatternEn'),
            'next_session_focus_en': llm_result.get('aiNextFocusEn'),
            'focus_tag_en': llm_result.get('aiFocusTagEn'),
            'session_insight_es': llm_result.get('aiSummaryEs'),
            'progress_pattern_es': llm_result.get('aiProgressPatternEs'),
            'next_session_focus_es': llm_result.get('aiNextFocusEs'),
            'focus_tag_es': llm_result.get('aiFocusTagEs'),
        }

        print(f"BACKEND_AI_FIX_VERSION: ai_fields_guard_v3")

        print(f"FINAL aiSummaryEn = {final_payload.get('aiSummaryEn')}")
        print(f"FINAL aiProgressPatternEn = {final_payload.get('aiProgressPatternEn')}")
        print(f"FINAL aiNextFocusEn = {final_payload.get('aiNextFocusEn')}")
        print(f"FINAL aiFocusTagEn = {final_payload.get('aiFocusTagEn')}")

        # SAFETY CHECK: If for any reason the keys are still null here, DO NOT return 200.
        required_out = ['aiSummaryEn', 'aiProgressPatternEn', 'aiNextFocusEn']
        is_output_valid = all(str(final_payload.get(k) or "").strip() not in ["", "null", "None"] for k in required_out)
        
        if not is_output_valid:
            print("LOG: AI_FIELDS_MISSING (Safety Check Triggered) — Fields were null/empty at final stage.")
            # DO NOT save to firestore, DO NOT increment limit
            raise HTTPException(status_code=422, detail="EMPTY_INSIGHT_FIELDS")

        # 6. Record in Firestore session document
        record_insight_in_session(uid, request.session_id, final_payload)
        print("[LLM] Insight recorded in Firestore.")

        # 7. Increment limit count ONLY after successful save
        increment_daily_limit(uid)
        
        return final_payload

    except HTTPException:
        raise
    except ValueError as ve:
        error_str = str(ve)
        print(f"[LLM] BACKEND_ERROR: {error_str}")
        # Identify specific failure types for logging
        if "AI_PARSE_FAILED" in error_str:
            print("LOG: AI_PARSE_FAILED")
        elif "AI_FIELDS_MISSING" in error_str:
            print("LOG: AI_FIELDS_MISSING")
            
        raise HTTPException(status_code=422, detail=error_str)
    except Exception as e:
        print(f"Error calling LLM Service: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/analyze_popup")
async def analyze_popup(
    video: UploadFile = File(...), 
    session_id: str = Form(""),
    current_user: dict = Depends(get_current_user)
):
    uid = current_user['uid']
    
    # 0. Enforce limits before processing video or calling OpenAI
    try:
        # 1. Per-session limit check: return if exists
        if session_id:
            existing = get_existing_insight(uid, session_id)
            if existing:
                print(f"BACKEND_AI_FIX_VERSION: ai_fields_guard_v3 (Popup Existing)")
                # Need to map back to popup structure if returning existing session
                return {
                    "BACKEND_AI_FIX_VERSION": "ai_fields_guard_v3",
                    "confidence_score": existing.get('aiConfidence', 0),
                    "metrics": {"popup_time_seconds": existing.get('aiPopupTime', 0)},
                    "feedback": {"primary_improvement": existing.get('aiSummaryEn', '')},
                    "note": "Returned existing insight"
                }
        
        # 2. Daily limit check: block if 3/3
        check_daily_limit(uid)
    except HTTPException:
        raise

    # 1. Validate file extension
    allowed_exts = [".mp4", ".mov", ".avi", ".mkv"]
    ext = os.path.splitext(video.filename)[1].lower()
    if ext not in allowed_exts:
        raise HTTPException(status_code=400, detail=f"Unsupported file type. Allowed: {', '.join(allowed_exts)}")
        
    temp_file_path = None
    try:
        # 2. Save video temporarily
        suffix = ext if ext else ".mp4"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_vid:
            temp_file_path = temp_vid.name
            
            # Read and check size simultaneously
            size = 0
            while content := await video.read(1024 * 1024): # 1MB chunks
                size += len(content)
                if size > MAX_FILE_SIZE:
                    temp_vid.close()
                    os.remove(temp_file_path)
                    raise HTTPException(status_code=413, detail=f"File exceeds maximum size of {MAX_FILE_SIZE / (1024*1024)}MB")
                temp_vid.write(content)
                
        # 3. Server-side duration validation (10s limit + 0.5s tolerance)
        import cv2
        cap = cv2.VideoCapture(temp_file_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = cap.get(cv2.CAP_PROP_FRAME_COUNT)
        duration = frame_count / fps if fps > 0 else 0
        cap.release()
        
        MAX_DURATION_TOLERANCE = 10.5
        if duration > MAX_DURATION_TOLERANCE:
            if temp_file_path and os.path.exists(temp_file_path):
                os.remove(temp_file_path)
            raise HTTPException(
                status_code=400, 
                detail=f"Video exceeds 10 second duration limit (detected {duration:.1f}s)"
            )
            
        # 4. Process video using analyzer module
        result = analyzer.process_video_frames(temp_file_path, target_fps=10)
        
        # 5. Record in session
        insight_data = {
            'aiSummaryEn': result['feedback']['primary_improvement'],
            'aiSummaryEs': result['feedback']['primary_improvement'],
            'aiConfidence': result['confidence_score'],
            'aiPopupTime': result['metrics']['popup_time_seconds'],
        }
        record_insight_in_session(uid, session_id, insight_data)
        
        # 6. Increment limit count ONLY after successful save
        increment_daily_limit(uid)

        # 7. Return results
        result['BACKEND_AI_FIX_VERSION'] = 'ai_fields_guard_v3'
        print(f"BACKEND_AI_FIX_VERSION: ai_fields_guard_v3 (Popup Fresh)")
        
        # SAFETY CHECK
        if not result.get('feedback', {}).get('primary_improvement'):
            print("LOG: AI_FIELDS_MISSING (Popup Safety Check Triggered)")
            raise HTTPException(status_code=422, detail="EMPTY_INSIGHT_FIELDS")

        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error during analysis: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="An error occurred while analyzing the video.")
        
    finally:
        # Clean up temporary files
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception as e:
                print(f"Warning: Could not delete temp file {temp_file_path}: {e}")

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
