#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/whisper-dictate.service"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/whisper-dictate.desktop"

if [ "$1" = "--disable" ]; then
    systemctl --user disable --now whisper-dictate.service || true
    rm -f "$SERVICE_FILE"
    rm -f "$DESKTOP_FILE"
    systemctl --user daemon-reload
    echo "Disabled Whisper Dictate autostart"
    exit 0
fi

mkdir -p "$SERVICE_DIR" "$DESKTOP_DIR"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Whisper Dictation Container
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --name whisper-app \
  -e HF_HUB_DISABLE_PROGRESS_BARS=1 \
  -e WHISPER_MODEL=${WHISPER_MODEL:-openai/whisper-base} \
  -e WHISPER_LANG=${WHISPER_LANG:-en} \
  -e WHISPER_OUTPUT_LANG=${WHISPER_OUTPUT_LANG:-} \
  -e WHISPER_PORT=${WHISPER_PORT:-8610} \
  -p 127.0.0.1:${WHISPER_PORT:-8610}:${WHISPER_PORT:-8610} \
  -v $PROJECT_DIR/recordings:/app/recordings:rw \
  -v $PROJECT_DIR/transcribe.py:/app/transcribe.py:ro \
  -v $PROJECT_DIR/server.py:/app/server.py:ro \
  -v $HOME/.cache/huggingface:/root/.cache/huggingface:rw \
  whisper-dictation sleep infinity
ExecStartPost=/usr/bin/docker exec -d \
  -e WHISPER_MODEL=${WHISPER_MODEL:-openai/whisper-base} \
  -e WHISPER_LANG=${WHISPER_LANG:-en} \
  -e WHISPER_OUTPUT_LANG=${WHISPER_OUTPUT_LANG:-} \
  -e WHISPER_PORT=${WHISPER_PORT:-8610} \
  whisper-app python /app/server.py
ExecStop=/usr/bin/docker exec whisper-app pkill -f "/app/server.py"
ExecStopPost=/usr/bin/docker stop whisper-app
ExecStopPost=/usr/bin/docker rm whisper-app

[Install]
WantedBy=default.target
EOF

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Whisper Dictate
Comment=Voice dictation hotkey (Ctrl+Shift+D)
Exec=$PROJECT_DIR/scripts/voice-dictate.sh
Icon=audio-input-microphone
Terminal=false
Type=Application
Categories=Utility;
EOF

systemctl --user daemon-reload
systemctl --user enable --now whisper-dictate.service

echo "Enabled Whisper Dictate autostart"
