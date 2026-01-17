import torch
from transformers import pipeline
from typing import Optional, Dict, Any
from pathlib import Path

from .config import Config, get_config, sanitize_language

DEFAULT_MODEL_ID = "openai/whisper-base"

_pipe = None

def load_model(config: Optional[Config] = None) -> pipeline:
    global _pipe
    if _pipe is None:
        config = config or get_config()
        _pipe = pipeline(
            task="automatic-speech-recognition",
            model=config.model,
            device=config.device,
            torch_dtype=torch.float32,
            cache_dir=str(config.model_cache_dir),
        )
    return _pipe

def transcribe(
    audio_path: Path,
    language: Optional[str] = None,
    output_language: Optional[str] = None,
    config: Optional[Config] = None,
) -> Dict[str, Any]:
    pipe = load_model(config)
    config = config or get_config()
    
    language = sanitize_language(language or config.language)
    output_language = sanitize_language(output_language or config.output_language)

    generate_kwargs: Dict[str, Any] = {
        "task": "transcribe",
        "max_new_tokens": 444,
    }
    
    if language:
        generate_kwargs["language"] = language
    if output_language:
        generate_kwargs["language"] = output_language

    result = pipe(
        str(audio_path),
        generate_kwargs=generate_kwargs,
        chunk_length_s=30,
        stride_length_s=5,
        return_timestamps=False,
    )
    
    return {
        "text": result["text"],
        "language": language or "auto",
    }

if __name__ == "__main__":
    import sys
    from .config import get_config
    
    if len(sys.argv) < 2:
        print("Usage: python -m backend.transcribe <audio_path>", file=sys.stderr)
        sys.exit(1)
    
    audio_path = Path(sys.argv[1])
    result = transcribe(audio_path)
    print(result["text"])
