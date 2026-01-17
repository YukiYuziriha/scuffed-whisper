# Whisper Dictation Desktop App

Desktop application for voice dictation using Whisper model.

## Features

- Global hotkey (Ctrl+Shift+D) to start/stop recording
- Overlay animation during recording and processing
- System tray icon with Quit option
- Settings for language, hotkey, and model selection
- Cross-platform: Windows 11 + Debian

## Installation (Development)

### Prerequisites

- Node.js 18+
- Python 3.8+
- Rust toolchain
- System dependencies:
  - Debian: `ffmpeg`, `python3`, `python3-pip`, `libwebkit2gtk-4.0-dev`
  - Windows: [Visual Studio C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp/)

### Setup

```bash
# Install frontend dependencies
npm install

# Install Python backend dependencies
python3 -m pip install -r backend/requirements.txt --user

# Install Tauri CLI
npm install -g @tauri-apps/cli

# Or via cargo
cargo install tauri-cli
```

## Running

```bash
# Development mode
npm run tauri dev

# Build for production
npm run tauri build
```

## Configuration

Settings are stored in localStorage:
- Language: auto, en, ru
- Hotkey: Ctrl+Shift+D (customizable)
- Model: tiny, base, small

## Backend API

Python backend runs on `http://127.0.0.1:8610`

### Endpoints

- `GET /health` - Health check
- `POST /record/start` - Start recording
- `POST /record/stop` - Stop recording
- `POST /transcribe` - Transcribe audio file

## Project Structure

```
src/
├── App.tsx              # Main app
├── Settings.tsx          # Settings modal
├── overlay/
│   ├── Overlay.tsx       # Recording overlay
│   └── overlay.css
├── state/
│   └── recorder.ts      # State machine
├── lib/
│   ├── api.ts           # Backend API client
│   └── hotkeys.ts      # Global shortcuts
src-tauri/
├── src/lib.rs          # Tauri backend (Rust)
├── Cargo.toml
└── tauri.conf.json
backend/
├── main.py             # FastAPI server
├── audio.py            # Audio capture
├── transcribe.py       # Whisper pipeline
├── config.py           # Configuration
└── requirements.txt
```

## License

MIT
