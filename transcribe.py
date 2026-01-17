import os
import sys
import torch
from transformers import AutoProcessor, VoxtralForConditionalGeneration

MODEL_ID = "mistralai/Voxtral-Mini-3B-2507"
LANGUAGE = os.getenv("VOXTRAL_LANG", "en").strip()
if not LANGUAGE or LANGUAGE.lower() == "auto":
    LANGUAGE = "en"

processor = AutoProcessor.from_pretrained(MODEL_ID)
model = VoxtralForConditionalGeneration.from_pretrained(
    MODEL_ID,
    dtype=torch.float32,
    device_map="cpu",
)

def transcribe(audio_path):
    request_kwargs = {
        "audio": audio_path,
        "model_id": MODEL_ID,
        "language": LANGUAGE,
    }

    inputs = processor.apply_transcription_request(**request_kwargs)
    inputs = inputs.to("cpu", dtype=torch.float32)

    outputs = model.generate(**inputs, max_new_tokens=500)
    text = processor.batch_decode(
        outputs[:, inputs.input_ids.shape[1]:],
        skip_special_tokens=True,
    )[0]

    print(text, flush=True)
    return text

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python transcribe.py <audio_path>", file=sys.stderr)
        sys.exit(1)
    transcribe(sys.argv[1])
