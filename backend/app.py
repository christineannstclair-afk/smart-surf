import os
import tempfile
import traceback
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv

# Load environment variables from .env file securely
load_dotenv()
import uvicorn

import analyzer
import llm_service

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
    return {"status": "ok", "service": "Smart Surf Pop-up Analyzer"}

# Dedicated model for Surfer Pro Reflections
class ReflectionRequest(BaseModel):
    focus: str = ""
    worked_on: str = ""
    felt_hard: str = ""
    felt_good: str = ""
    conditions: str = ""
    notes: str = ""
    language: str = "en"

@app.post("/api/analyze_reflection")
async def analyze_reflection(request: ReflectionRequest):
    try:
        # Calls the dedicated llm_service specifically for the 3-part structured JSON
        result = llm_service.generate_reflection(
            focus=request.focus,
            worked_on=request.worked_on,
            felt_hard=request.felt_hard,
            felt_good=request.felt_good,
            conditions=request.conditions,
            notes=request.notes,
            language=request.language
        )
        return result
    except ValueError as ve:
        raise HTTPException(status_code=500, detail=str(ve))
    except Exception as e:
        print(f"Error calling LLM Service: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Failed to generate AI session reflection.")

@app.post("/api/analyze_popup")
async def analyze_popup(video: UploadFile = File(...)):
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
                
        # 3. Process video using analyzer module
        result = analyzer.process_video_frames(temp_file_path, target_fps=10)
        
        # 4. Return results
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error during analysis: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="An error occurred while analyzing the video.")
        
    finally:
        # 5. Clean up temporary files
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception as e:
                print(f"Warning: Could not delete temp file {temp_file_path}: {e}")

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
