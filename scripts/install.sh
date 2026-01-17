#!/bin/bash
set -e

echo "=== Installing Whisper Dictation ==="
echo ""

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose
    sudo usermod -aG docker $USER
    echo "Added $USER to docker group. Please log out and back in, or run:"
    echo "  newgrp docker"
    echo ""
fi

if ! command -v xclip &> /dev/null; then
    echo "Installing xclip..."
    sudo apt-get install -y xclip
fi

if ! command -v arecord &> /dev/null; then
    echo "Installing arecord (ALSA)..."
    sudo apt-get install -y alsa-utils
fi

if ! command -v paplay &> /dev/null; then
    echo "Installing paplay (PulseAudio) for sounds..."
    sudo apt-get install -y pulseaudio-utils
fi

if ! command -v notify-send &> /dev/null; then
    echo "Installing notify-send (desktop notifications)..."
    sudo apt-get install -y libnotify-bin
fi

echo ""
echo "Dependencies installed. Now build the Docker image:"
echo "  make build"
echo ""
echo "Enable autostart service:"
echo "  make enable-service"
echo ""
echo "Then set up keyboard shortcut in Settings → Keyboard → Custom Shortcuts:"
echo "  Command: $PWD/scripts/voice-dictate.sh"
echo ""
