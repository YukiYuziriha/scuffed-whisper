#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/voxtral-dictate.service"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/voxtral-dictate.desktop"

if [ "$1" = "--disable" ]; then
    systemctl --user disable --now voxtral-dictate.service || true
    rm -f "$SERVICE_FILE"
    rm -f "$DESKTOP_FILE"
    systemctl --user daemon-reload
    echo "Disabled Voxtral Dictate autostart"
    exit 0
fi

mkdir -p "$SERVICE_DIR" "$DESKTOP_DIR"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Voxtral Dictation Container
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --name voxtral-app \
  -e HF_HUB_DISABLE_PROGRESS_BARS=1 \
  -v $PROJECT_DIR/recordings:/app/recordings:rw \
  -v $PROJECT_DIR/transcribe.py:/app/transcribe.py:ro \
  -v $HOME/.cache/huggingface:/root/.cache/huggingface:rw \
  voxtral-dictation sleep infinity
ExecStop=/usr/bin/docker stop voxtral-app
ExecStopPost=/usr/bin/docker rm voxtral-app

[Install]
WantedBy=default.target
EOF

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Voxtral Dictate
Comment=Voice dictation hotkey (Ctrl+Shift+D)
Exec=$PROJECT_DIR/scripts/voice-dictate.sh
Icon=audio-input-microphone
Terminal=false
Type=Application
Categories=Utility;
EOF

systemctl --user daemon-reload
systemctl --user enable --now voxtral-dictate.service

echo "Enabled Voxtral Dictate autostart"
