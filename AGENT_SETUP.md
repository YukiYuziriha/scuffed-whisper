# Repo Setup (for agents)

This repo runs Whisper dictation in Docker and exposes a host hotkey.

## One-time setup

```bash
./scripts/install.sh
make build
make run
make enable-service
```

## Hotkey behavior

- Press hotkey once → start recording
- Press again → transcribe and copy to clipboard
- Notifications show state (recording / transcribing / ready)

## Language and device overrides

Set environment variables before calling the hotkey script:

- `WHISPER_LANG=auto` (default), `en`, `ru`, etc.
- `WHISPER_AUDIO_DEVICE=hw:1,0` to force mic device

## No rebuilds for script changes

`transcribe.py` is mounted into the container at runtime. You can edit it and restart the container without rebuilding.

## Notes

- Model cache is persisted to `~/.cache/huggingface`
- Container name: `whisper-app`
- Start/stop via `make run` / `make stop`
- Autostart via `make enable-service`
