# Quick Reference

## Setup (one time)
```bash
./scripts/install.sh
make build
make run
```

## Set Keyboard Shortcut
1. Open Settings
2. Keyboard → View and Customize Shortcuts → Custom Shortcuts
3. Click + to add:
   - Name: Voice Dictate
   - Command: /home/yuki/Projects/scuffed-whisper/scripts/voice-dictate.sh
   - Shortcut: Ctrl+Shift+D

## Use
1. Press Ctrl+Shift+D → **start recording** (you'll hear a sound)
2. Speak
3. Press Ctrl+Shift+D → **stop and transcribe** (you'll hear completion sound)
4. Ctrl+V to paste anywhere

## Notes
- First run downloads ~6GB model (10-15 min)
- Subsequent transcriptions are much faster
- On AMD GPU: runs CPU-only (no CUDA support)
- Compatible with Wayland (uses host xclip)
