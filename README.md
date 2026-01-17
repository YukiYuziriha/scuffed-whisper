# Whisper Dictation for Ubuntu (Wayland)

Keyboard shortcut voice dictation using OpenAI Whisper model.

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

## Configuration

- `WHISPER_LANG` (default: `en`) - input language hint. Supports `en`, `ru`, `english`, `russian`.
- `WHISPER_OUTPUT_LANG` - strict output language hint (e.g., `en` or `ru`). Forces transcription to this language.
- `WHISPER_MODEL` (default: `openai/whisper-base`) - model id (restart daemon/service after changing). Available models: `tiny`, `base`, `small`, `medium`, `large-v3`, `large-v3-turbo`.
- `WHISPER_PORT` (default: `8610`) - daemon port (host).

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

If you change `WHISPER_MODEL`, `WHISPER_LANG`, or `WHISPER_OUTPUT_LANG`, restart the service:
```bash
make disable-service
make enable-service
```

## Usage

1. Press shortcut to **start recording**
2. Speak
3. Press shortcut again to **transcribe and copy to clipboard**
4. Paste anywhere with Ctrl+V

## How It Works

- Recording stored in `recordings/` directory
- Docker container runs CPU-only Whisper model (compatible with AMD integrated GPU)
- HuggingFace cache persisted at `~/.cache/huggingface` to avoid repeated downloads
- Transcribe script mounted from host, so no rebuilds needed for script changes
- Daemon keeps model warm and accepts HTTP transcription requests
- Transcription written to temp file, then copied via host `xclip` (Wayland compatible)
- Audio + desktop notifications for recording/transcribing/ready

## File Locations

- Recordings: `recordings/dictation.wav`
- Temp transcript: `/tmp/whisper-transcript.txt`
- Container: `whisper-app`
- Daemon: `http://127.0.0.1:8610`

## Troubleshooting

- Check container: `docker ps`
- View logs: `docker logs whisper-app`
- Stop: `make stop`
- Rebuild: `make clean && make build`
