#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RECORDING_DIR="$PROJECT_DIR/recordings"
HF_CACHE_DIR="$HOME/.cache/huggingface"
TRANSCRIPT_FILE="/tmp/whisper-transcript.txt"
LANGUAGE="${WHISPER_LANG:-auto}"
OUTPUT_LANGUAGE="${WHISPER_OUTPUT_LANG:-}"
MODEL_ID="${WHISPER_MODEL:-}"
DAEMON_PORT="${WHISPER_PORT:-8610}"
DAEMON_HOST="127.0.0.1"
DAEMON_URL="http://${DAEMON_HOST}:${DAEMON_PORT}"
RECORD_DEVICE="${WHISPER_AUDIO_DEVICE:-}"
IMAGE_NAME="whisper-dictation"
CONTAINER_NAME="whisper-app"

mkdir -p "$RECORDING_DIR"

PID_FILE="$RECORDING_DIR/.recording.pid"

toggle_recording() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID"
            rm -f "$PID_FILE"
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

if toggle_recording; then
    sleep 0.5

    if [ ! -d "$HF_CACHE_DIR" ]; then
        mkdir -p "$HF_CACHE_DIR"
    fi

    notify-send "Whisper Dictate" "Transcribing..." -i media-playback-start || true

    if ! curl -sf "$DAEMON_URL/health" > /dev/null; then
        if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
            docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME" && docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
            docker run -d --name "$CONTAINER_NAME" \
                -e HF_HUB_DISABLE_PROGRESS_BARS=1 \
                -e WHISPER_MODEL="$MODEL_ID" \
                -e WHISPER_LANG="$LANGUAGE" \
                -e WHISPER_OUTPUT_LANG="$OUTPUT_LANGUAGE" \
                -e WHISPER_PORT="$DAEMON_PORT" \
                -p 127.0.0.1:"$DAEMON_PORT":"$DAEMON_PORT" \
                -v "$PROJECT_DIR/recordings:/app/recordings:rw" \
                -v "$PROJECT_DIR/transcribe.py:/app/transcribe.py:ro" \
                -v "$PROJECT_DIR/server.py:/app/server.py:ro" \
                -v "$HF_CACHE_DIR:/root/.cache/huggingface:rw" \
                "$IMAGE_NAME" sleep infinity > /dev/null 2>&1 || true
        fi

        docker exec -d -e WHISPER_LANG="$LANGUAGE" -e WHISPER_OUTPUT_LANG="$OUTPUT_LANGUAGE" -e WHISPER_MODEL="$MODEL_ID" -e WHISPER_PORT="$DAEMON_PORT" "$CONTAINER_NAME" python /app/server.py > /dev/null 2>&1 || true
        for _ in $(seq 1 20); do
            if curl -sf "$DAEMON_URL/health" > /dev/null; then
                break
            fi
            sleep 0.5
        done
    fi

    if curl -sf "$DAEMON_URL/health" > /dev/null; then
        if [ -n "$OUTPUT_LANGUAGE" ]; then
            OUTPUT_PARAM="&output_language=$OUTPUT_LANGUAGE"
        else
            OUTPUT_PARAM=""
        fi

        curl -sf -X POST \
            --data-binary "@${RECORDING_DIR}/dictation.wav" \
            "$DAEMON_URL/transcribe?language=$LANGUAGE$OUTPUT_PARAM" \
            | python3 -c "import json,sys; payload=json.load(sys.stdin); text=payload.get('text',''); sys.stdout.write(text)" > "$TRANSCRIPT_FILE" 2>/dev/null || true
    else
        docker exec -e WHISPER_LANG="$LANGUAGE" -e WHISPER_OUTPUT_LANG="$OUTPUT_LANGUAGE" -e WHISPER_MODEL="$MODEL_ID" -e HF_HUB_DISABLE_PROGRESS_BARS=1 "$CONTAINER_NAME" python /app/transcribe.py /app/recordings/dictation.wav > "$TRANSCRIPT_FILE" 2>&1 || true
    fi


    if [ -s "$TRANSCRIPT_FILE" ]; then
        cat "$TRANSCRIPT_FILE" | xclip -selection clipboard
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
        notify-send "Whisper Dictate" "Ready (copied to clipboard)" -i dialog-information || true
    else
        paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga 2>/dev/null || true
        notify-send "Whisper Dictate" "Transcription failed" -i dialog-error || true
    fi

    rm -f "$TRANSCRIPT_FILE"
else
    if [ -n "$RECORD_DEVICE" ]; then
        arecord -f cd -t wav "$RECORDING_DIR/dictation.wav" -D "$RECORD_DEVICE" &
    else
        arecord -f cd -t wav "$RECORDING_DIR/dictation.wav" &
    fi
    echo $! > "$PID_FILE"
    paplay /usr/share/sounds/freedesktop/stereo/message.oga 2>/dev/null || true
    notify-send "Whisper Dictate" "Recording..." -i audio-input-microphone || true
fi
