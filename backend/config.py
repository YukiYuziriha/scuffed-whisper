import os
from pathlib import Path
from typing import Optional

DEFAULT_MODEL = "openai/whisper-base"
DEFAULT_LANGUAGE = "auto"
DEFAULT_PORT = 8610
DEFAULT_DEVICE = "cpu"

TEMP_DIR = Path.home() / ".whisper-dictation" / "temp"
MODEL_CACHE_DIR = Path.home() / ".whisper-dictation" / "models"

TEMP_DIR.mkdir(parents=True, exist_ok=True)
MODEL_CACHE_DIR.mkdir(parents=True, exist_ok=True)

class Config:
    def __init__(self):
        self.model = os.getenv("WHISPER_MODEL", DEFAULT_MODEL)
        self.language = os.getenv("WHISPER_LANG", DEFAULT_LANGUAGE)
        self.output_language = os.getenv("WHISPER_OUTPUT_LANG", DEFAULT_LANGUAGE)
        self.port = int(os.getenv("WHISPER_PORT", DEFAULT_PORT))
        self.device = os.getenv("WHISPER_DEVICE", DEFAULT_DEVICE)
        self.temp_dir = TEMP_DIR
        self.model_cache_dir = MODEL_CACHE_DIR
        self.sample_rate = 16000
        self.channels = 1

    def get_audio_file(self, filename: str) -> Path:
        return self.temp_dir / filename

def get_config() -> Config:
    return Config()

def sanitize_language(lang: Optional[str]) -> Optional[str]:
    if not lang or lang.lower() == "auto":
        return None
    return lang.lower()
