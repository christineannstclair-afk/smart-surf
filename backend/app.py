import os
import tempfile
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
    print(f"[Firebase] Initialization failed ({type(e).__name__}).")
    db = None

def get_current_user(authorization: str = Header(None)):
    """Require a valid Firebase ID token for every protected API request."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    scheme, separator, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not separator or not token.strip():
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    if _firebase_init_source == "none":
        raise HTTPException(status_code=503, detail="Authentication service unavailable")
    try:
        return auth.verify_id_token(token.strip())
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired authentication token")

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


                res = data.copy()
                res['BACKEND_AI_FIX_VERSION'] = 'ai_fields_guard_v3'
                return res
            else:
                # Check legacy keys too
                legacy = ['session_insight_en', 'progress_pattern_en', 'next_session_focus_en']
                is_legacy_complete = all(str(data.get(k) or "").strip() not in ["", "null", "None"] for k in legacy)
                if is_legacy_complete:


                    res = data.copy()
                    res['BACKEND_AI_FIX_VERSION'] = 'ai_fields_guard_v3'
                    return res
                

    except Exception:
        print("[Firestore] Existing insight lookup failed.")
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
            



        
        # 1. Free-Tier Gate
        if not is_pro and used_first_free:

            raise HTTPException(
                status_code=403, 
                detail={
                    "error": "paywall_required",
                    "message": "You've used your one free insight. Upgrade to Surfer Pro for unlimited insights!"
                }
            )

        # 2. Daily Limit Gate (for everyone)
        if count >= 3:

            raise HTTPException(
                status_code=429, 
                detail={
                    "error": "daily_limit_reached",
                    "message": "Daily insight limit reached. You can generate up to 3 insights per day."
                }
            )
        
        return count
        

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
        print("[LimitIncrement] Daily insight count updated.")
    except Exception:
        print("[LimitIncrement] Failed to update daily insight count.")

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

# Browser-based clients must explicitly configure allowed origins.
# Native Flutter clients are not governed by browser CORS.
allowed_origins = [origin.strip() for origin in os.getenv("CORS_ALLOWED_ORIGINS", "").split(",") if origin.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "Smart Surf Pop-up Analyzer",
        "deploy": "594f965",
    }

# Public diagnostic routes removed; health_check exposes no configuration.

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


    try:
        # 1. Per-session check: return existing if it was already generated
        if request.session_id:
            existing = get_existing_insight(uid, request.session_id)
            if existing and not force_refresh:





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
                print("[History] Could not fetch recent sessions.")

        # 4. Call the LLM
        print("[LLM] Generating session reflection.")
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








        # SAFETY CHECK: If for any reason the keys are still null here, DO NOT return 200.
        required_out = ['aiSummaryEn', 'aiProgressPatternEn', 'aiNextFocusEn']
        is_output_valid = all(str(final_payload.get(k) or "").strip() not in ["", "null", "None"] for k in required_out)
        
        if not is_output_valid:
            print("LOG: AI_FIELDS_MISSING")
            # DO NOT save to firestore, DO NOT increment limit
            raise HTTPException(status_code=422, detail="EMPTY_INSIGHT_FIELDS")

        # 6. Record in Firestore session document
        record_insight_in_session(uid, request.session_id, final_payload)


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
            
        raise HTTPException(status_code=422, detail="AI_GENERATION_FAILED")
    except Exception as e:
        print(f"[LLM] Unexpected failure ({type(e).__name__}).")
        raise HTTPException(status_code=500, detail="An error occurred while generating the reflection.")

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

        
        # SAFETY CHECK
        if not result.get('feedback', {}).get('primary_improvement'):
            print("LOG: AI_FIELDS_MISSING")
            raise HTTPException(status_code=422, detail="EMPTY_INSIGHT_FIELDS")

        return result