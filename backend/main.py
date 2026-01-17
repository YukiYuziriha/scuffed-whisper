import os
import sys
from pathlib import Path
from typing import Optional
import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import JSONResponse, FileResponse
import uvicorn

from .config import get_config
from .audio import AudioRecorder
from .transcribe import transcribe

app = FastAPI(title="Whisper Dictation Backend")
config = get_config()
recorder = AudioRecorder(config)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

@app.post("/record/start")
async def start_recording():
    try:
        audio_file = recorder.start_recording()
        return {"status": "recording", "audio_file": str(audio_file)}
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/record/stop")
async def stop_recording():
    try:
        audio_file = recorder.stop_recording()
        return {"status": "stopped", "audio_file": str(audio_file)}
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/transcribe")
async def transcribe_audio(
    audio_file: str = Form(...),
    language: Optional[str] = Form(None),
):
    try:
        audio_path = Path(audio_file)
        if not audio_path.exists():
            raise HTTPException(status_code=404, detail="Audio file not found")

        result = transcribe(audio_path, language=language, config=config)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def main():
    host = os.getenv("WHISPER_HOST", "127.0.0.1")
    port = config.port
    
    print(f"Starting Whisper Dictation Backend on {host}:{port}")
    print(f"Model: {config.model}")
    print(f"Language: {config.language}")
    
    uvicorn.run(app, host=host, port=port, log_level="info")

if __name__ == "__main__":
    main()
