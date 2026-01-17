# Voxtral Dictation for Ubuntu (Wayland)

Keyboard shortcut voice dictation using Voxtral AI model.

## Prerequisites

- Docker
- xclip
- arecord (ALSA)
- paplay (PulseAudio, optional for sounds)

## Installation

```bash
./scripts/install.sh
```

Or install manually:
```bash
sudo apt-get install -y docker.io xclip alsa-utils pulseaudio-utils
sudo usermod -aG docker $USER
newgrp docker  # Or log out and back in
```

## Quick Start

```bash
make build
make run
make enable-service

# Test recording (USB mic example)
arecord -f cd -t wav recordings/test.wav -d 3 -D hw:1,0

# Test transcription
make test
```

## Setup Keyboard Shortcut

1. Go to Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts
2. Add shortcut:
   - Name: "Voice Dictate"
   - Command: `/home/yuki/Projects/scuffed-whisper/scripts/voice-dictate.sh`
   - Shortcut: Ctrl+Shift+D

## Autostart (Systemd User Service)

```bash
make enable-service
```

To disable:
```bash
make disable-service
```

## Usage

1. Press shortcut to **start recording**
2. Speak
3. Press shortcut again to **transcribe and copy to clipboard**
4. Paste anywhere with Ctrl+V

## How It Works

- Recording stored in `recordings/` directory
- Docker container runs CPU-only Voxtral model (compatible with AMD integrated GPU)
- HuggingFace cache persisted at `~/.cache/huggingface` to avoid repeated downloads/conversions
- Transcribe script mounted from host, so no rebuilds needed for script changes
- Transcription written to temp file, then copied via host `xclip` (Wayland compatible)
- Audio + desktop notifications for recording/transcribing/ready

## File Locations

- Recordings: `recordings/dictation.wav`
- Temp transcript: `/tmp/voxtral-transcript.txt`
- Container: `voxtral-app`

## Troubleshooting

- Check container: `docker ps`
- View logs: `docker logs voxtral-app`
- Stop: `make stop`
- Rebuild: `make clean && make build`
