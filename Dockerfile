FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    torch torchaudio \
    transformers \
    accelerate \
    librosa \
    scipy \
    soundfile \
    mistral-common

WORKDIR /app
COPY transcribe.py .

CMD ["python", "transcribe.py"]
