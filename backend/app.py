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
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    token = authorization.split("Bearer ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        print(f"[Auth] Token verification FAILED: {type(e).__name__}: {e}")
        print(f"[Auth] Firebase init source was: {_firebase_init_source}")
        print(f"[Auth] Token prefix: {token[:30]}...")
        raise HTTPException(status_code=401, detail=f"Token verification failed: {type(e).__name__}")

def get_existing_insight(uid: str, session_id: str):
    """Checks if a session already has an AI insight and returns it if it does."""
    if not db or not session_id:
        return None
    
    try:
        session_ref = db.collection('users').document(uid).collection('sessions').document(session_id)
        doc = session_ref.get()
        if doc.exists:
            data = doc.to_dict()
            # If any insight fields exist, we consider it "already analyzed"
            if any(key in data for key in ['session_insight_en', 'aiSummaryEn', 'session_insight']):
                print(f"DEBUG: Found existing insight for session {session_id}")
                return data
    except Exception as e:
        print(f"Error checking existing insight: {e}")
    return None

def atomic_check_and_increment_limit(uid: str):
    """
    Enforces the 3-per-day AI insight limit and increments it atomically 
    BEFORE the expensive AI call. Returns the current usage count.
    """
    if not db: return
    
    from datetime import datetime, timezone
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    user_ref = db.collection('users').document(uid)

    def update_in_transaction(transaction):
        snapshot = user_ref.get(transaction=transaction)
        
        current_count = 0
        if snapshot.exists:
            data = snapshot.to_dict()
            last_date = data.get('lastAiInsightDate')
            
            if last_date == today_str:
                current_count = data.get('aiInsightsTodayCount', 0)
                if current_count >= 3:
                    # Raise a standard exception that we catch outside
                    raise ValueError("LIMIT_REACHED")
        
        # Atomically increment
        new_count = current_count + 1
        transaction.set(user_ref, {
            'aiInsightsTodayCount': new_count,
            'lastAiInsightDate': today_str,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        return new_count

    try:
        new_count = db.run_transaction(update_in_transaction)
        print(f"DEBUG: Usage for {uid} incremented to {new_count}/3 for {today_str} (UTC)")
    except ValueError as ve:
        if str(ve) == "LIMIT_REACHED":
            print(f"DEBUG: Limit reached for {uid}")
            raise HTTPException(status_code=403, detail="Daily AI insight limit reached (3/3)")
        raise
    except Exception as e:
        print(f"DEBUG: Transaction failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to enforce usage limits")

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
async def analyze_reflection(request: ReflectionRequest, current_user: dict = Depends(get_current_user), force_refresh: bool = False):
    uid = current_user['uid']
    try:
        # 1. Per-session cache check — skip if force_refresh=true (for testing new prompts)
        if request.session_id and not force_refresh:
            existing = get_existing_insight(uid, request.session_id)
            if existing:
                print(f"[Cache] Returning cached insight for session {request.session_id}. Use ?force_refresh=true to bypass.")
                return existing
        elif request.session_id and force_refresh:
            print(f"[Cache] force_refresh=true — bypassing Firestore cache for session {request.session_id}")
        
        # 2. Daily limit check & Atomic Increment: block if 3/3
        atomic_check_and_increment_limit(uid)
        
        # 3. Fetch recent sessions for pattern recognition
        history = []
        if db:
            sessions_query = db.collection('users').document(uid).collection('sessions')\
                .order_by('createdAt', direction=firestore.Query.DESCENDING)\
                .limit(3).get()
            for doc in sessions_query:
                history.append(doc.to_dict())

        # 4. Calls the LLM
        result = llm_service.generate_reflection(
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
        
        # 5. Success! Record in session
        record_insight_in_session(uid, request.session_id, result)
        
        return result
    except HTTPException:
        raise
    except ValueError as ve:
        raise HTTPException(status_code=500, detail=str(ve))
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
                # Need to map back to popup structure if returning existing session
                return {
                    "confidence_score": existing.get('aiConfidence', 0),
                    "metrics": {"popup_time_seconds": existing.get('aiPopupTime', 0)},
                    "feedback": {"primary_improvement": existing.get('aiSummaryEn', '')},
                    "note": "Returned existing insight"
                }
        
        # 2. Daily limit check & Atomic Increment: block if 3/3
        atomic_check_and_increment_limit(uid)
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
        
        # 6. Return results
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
