import os
import sys
import torch
from transformers import pipeline

DEFAULT_MODEL_ID = "openai/whisper-base"
MODEL_ID = os.getenv("WHISPER_MODEL", DEFAULT_MODEL_ID).strip() or DEFAULT_MODEL_ID
WHISPER_LANG_MAP = {
    "en": "english",
    "english": "english",
    "ru": "russian",
    "russian": "russian",
}


def sanitize_language(value, default="en"):
    if not value:
        return default
    value = value.strip().lower()
    if not value or value == "auto":
        return default
    return WHISPER_LANG_MAP.get(value, default)


def sanitize_output_language(value):
    if not value:
        return ""
    value = value.strip().lower()
    if not value or value == "auto":
        return ""
    return WHISPER_LANG_MAP.get(value, "")


_pipe = None


def load_model():
    global _pipe
    if _pipe is None:
        _pipe = pipeline(
            task="automatic-speech-recognition",
            model=MODEL_ID,
            device="cpu",
            torch_dtype=torch.float32,
        )
    return _pipe


def transcribe(audio_path, language=None, output_language=None, print_output=True):
    pipe = load_model()
    language = sanitize_language(language or os.getenv("WHISPER_LANG", "en"))
    output_language = sanitize_output_language(
        output_language or os.getenv("WHISPER_OUTPUT_LANG", "")
    )

    generate_kwargs = {
        "language": language,
        "task": "transcribe",
        "max_new_tokens": 444,
    }
    if output_language:
        generate_kwargs["language"] = output_language

    result = pipe(
        audio_path,
        generate_kwargs=generate_kwargs,
        chunk_length_s=30,
        stride_length_s=5,
        return_timestamps=False,
    )
    text = result["text"]

    if print_output:
        print(text, flush=True)
    return text


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python transcribe.py <audio_path>", file=sys.stderr)
        sys.exit(1)

    transcribe(sys.argv[1])
