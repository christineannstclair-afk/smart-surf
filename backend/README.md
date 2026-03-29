# Smart Surf Pop-up Analyzer API

A minimal Python FastAPI backend using MediaPipe Pose to analyze surfing pop-ups. It processes a video file, calculates movement metrics out of the water, and returns structured feedback.

## Features
- **FastAPI**: High-performance async API.
- **MediaPipe Pose**: Tracks 33 body landmarks to calculate angles and positions.
- **Intelligent Metrics**: Calculates `popup_time_seconds`, `knee_angle_min`, `stance_width_ratio`, and `back_angle_at_stand`.
- **Automated Feedback**: Generates 3 actionable bullet points (Solid, Improvement, Drill) entirely based on the raw metrics.

## Local Development

### 1. Prerequisites
- Python 3.9+
- Provide a virtual environment:

```bash
python -m venv venv
```

### 2. Install Dependencies
Activate the virtual environment:
- Windows: `.\venv\Scripts\activate`
- macOS/Linux: `source venv/bin/activate`

Then install requirements:
```bash
pip install -r requirements.txt
```

### 3. Run the Server
Start the Uvicorn server:
```bash
uvicorn app:app --reload
```
The server will be available at `http://localhost:8000`.

### 4. Test the API
You can test the health endpoint:
```bash
curl http://localhost:8000/health
```

Or view the interactive API documentation provided by FastAPI at `http://localhost:8000/docs`.

## Deployment Recommendations
For deployment, it is highly recommended to use a Docker container, especially because OpenCV and MediaPipe have system-level dependencies. 

A standard deployment using platforms like Render, Heroku, or AWS App Runner will work well. Ensure your server instance has at least 1GB of RAM to comfortably run the MediaPipe inference models.
