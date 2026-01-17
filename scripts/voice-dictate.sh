#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RECORDING_DIR="$PROJECT_DIR/recordings"
HF_CACHE_DIR="$HOME/.cache/huggingface"
TRANSCRIPT_FILE="/tmp/voxtral-transcript.txt"
LANGUAGE="${VOXTRAL_LANG:-auto}"
RECORD_DEVICE="${VOXTRAL_AUDIO_DEVICE:-}"

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

    notify-send "Voxtral Dictate" "Transcribing..." -i media-playback-start || true

    docker exec -e VOXTRAL_LANG="$LANGUAGE" -e HF_HUB_DISABLE_PROGRESS_BARS=1 voxtral-app python /app/transcribe.py /app/recordings/dictation.wav > "$TRANSCRIPT_FILE" 2>&1 || true

    if [ -s "$TRANSCRIPT_FILE" ]; then
        cat "$TRANSCRIPT_FILE" | xclip -selection clipboard
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
        notify-send "Voxtral Dictate" "Ready (copied to clipboard)" -i dialog-information || true
    else
        paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga 2>/dev/null || true
        notify-send "Voxtral Dictate" "Transcription failed" -i dialog-error || true
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
    notify-send "Voxtral Dictate" "Recording..." -i audio-input-microphone || true
fi
