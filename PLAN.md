# Plan: Background daemon + language control + model selection

## Goals
- Add a long-running background daemon inside the container to keep the model warm.
- Provide a strict output language option to reduce cross-language drift.
- Allow selecting a smaller Voxtral model via env configuration.

## Assumptions
- Voxtral model remains local in container; we communicate via localhost HTTP.
- Hotkey script can call `curl` to send audio to the daemon.
- There is a smaller Voxtral model; if not, we will document that the env var defaults to current.

## Steps
1. Create a daemon entry point (e.g., `server.py`) that:
   - Loads model once at startup.
   - Exposes `POST /transcribe` accepting audio bytes.
   - Accepts `language` and `output_language` params.
   - Returns transcription text in JSON.
2. Update `scripts/voice-dictate.sh` to:
   - Check if daemon is up; start via docker if not.
   - Send recorded audio to the daemon with `curl`.
   - Parse JSON result for clipboard.
3. Extend `transcribe.py` (or shared utils) to:
   - Accept `VOXTRAL_MODEL` and `VOXTRAL_OUTPUT_LANG`.
   - Enforce `output_language` when set.
4. Add configuration to `Makefile`/service docs:
   - Show new env vars.
   - Add daemon start/stop targets if needed.
5. Verify with a sample run and document expected workflow.
