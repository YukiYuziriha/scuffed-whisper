# Tauri + Python Backend Implementation Plan

**Project**: Whisper Dictation Desktop App  
**Platforms**: Windows 11 + Debian  
**Tech Stack**: Tauri (Rust) + Python (Whisper) + React/JS

## Goals

- Single desktop app that records, transcribes, and pastes to clipboard
- Global hotkey (Ctrl+Shift+D) to start/stop recording
- Overlay animation during recording and processing (no notification spam)
- Tray icon with Quit option
- "Just works" installers for Windows and Debian
- No Docker, no systemd services

## Architecture

### High-Level Components
1. **Tauri App** - UI, overlay, hotkey, tray/quit, process management
2. **Python Backend** - Audio capture + Whisper inference
3. **IPC Layer** - HTTP or stdin/stdout between Tauri and Python

### Planned Repository Layout

```
src/
├── App.tsx                          # Main UI shell, settings
├── overlay/
│   ├── Overlay.tsx                  # Recording/processing animation
│   └── overlay.css                  # Animation visuals
├── state/
│   └── recorder.ts                  # State machine: idle/recording/processing
├── lib/
│   ├── api.ts                       # IPC client to backend
│   └── hotkeys.ts                   # Register/unregister hotkeys
src-tauri/
├── src/
│   └── main.rs                      # Tauri bootstrap: windows, tray, hotkeys, backend process
├── tauri.conf.json                  # Window config defaults
└── Cargo.toml                       # Plugins: global shortcut, tray
backend/
├── main.py                          # Entrypoint: server + inference
├── audio.py                         # Record + VAD
├── transcribe.py                    # Whisper pipeline
└── config.py                        # Model, language, device
scripts/
├── build-backend.sh                 # Bundle/prepare Python for release
└── dev-backend.sh                   # Run Python backend in dev
package.json                         # Frontend + tauri commands
```

## Phase 1: Tauri App Shell + Overlay Window

### 1.1 Tauri Bootstrap
- Create standard Tauri project with React/Vite frontend
- Add `tauri-plugin-global-shortcut` dependency
- Enable `tray-icon` feature in `tauri`

### 1.2 Overlay Window (Rust)
Create dedicated overlay window in `src-tauri/src/main.rs`:
- Transparent background
- Always-on-top
- No decorations (frameless)
- Optionally click-through

Pattern (from Tauri v2 docs):
```rust
tauri::WebviewWindowBuilder::new(app, "overlay", tauri::WebviewUrl::App("index.html".into()))
  .transparent(true)
  .decorations(false)
  .always_on_top(true)
  .build()?;
```

Add runtime toggle for overlay visibility.

### 1.3 Overlay UI
Create `src/overlay/Overlay.tsx`:
- Floating mic icon + pulsing ring OR full-screen tinted overlay
- States:
  - `idle` (hidden)
  - `recording` (pulsing animation)
  - `processing` (spinner/progress)
  - `error` (red blink)

## Phase 2: Global Hotkey + State Machine

### 2.1 Global Shortcut Registration
Pattern (from Tauri v2 plugin docs):
```typescript
import { register, unregister } from '@tauri-apps/plugin-global-shortcut';

await register('CommandOrControl+Shift+D', (event) => {
  if (event.state === 'Pressed') {
    toggleRecord();
  }
});
```

### 2.2 Recorder State Machine
Create `src/state/recorder.ts`:
- State enum: `idle | recording | processing | error`
- Transitions:
  - `idle -> recording` (on hotkey press)
  - `recording -> processing` (on hotkey press again)
  - `processing -> idle` (on transcription complete)
  - `any -> error` (on failure)
- State changes drive overlay visibility and animation

## Phase 3: Backend Process (Python)

### 3.1 Backend Process Management
Tauri responsibilities in `src-tauri/src/main.rs`:
- Start Python backend on app launch
- Monitor backend health
- Terminate backend on app exit

### 3.2 IPC Choice
Two options (decide based on testing):
1. **HTTP localhost** (simple, debug-friendly)
   - `http://127.0.0.1:8610/record/start`
   - `http://127.0.0.1:8610/record/stop`
   - `http://127.0.0.1:8610/transcribe`
   - `http://127.0.0.1:8610/health`
2. **stdin/stdout JSON** (single process, lower overhead)

### 3.3 Whisper Pipeline
Python backend structure:
- `backend/main.py` - Entrypoint, API server
- `backend/audio.py` - Audio capture + VAD (voice activity detection)
- `backend/transcribe.py` - Whisper pipeline with caching
- `backend/config.py` - Model, language, device config

Keep model loaded in memory to reduce latency.

## Phase 4: Tray + Exit Control

### 4.1 Tray Icon & Menu
Add tray icon in `src-tauri/src/main.rs`:
- Menu items: "Quit", "Open Settings", "Toggle Overlay"
- Click handler for tray icon

Pattern (from Tauri v2 docs):
```rust
tauri::Builder::default()
  .on_tray_icon_event(|app, event| {
    // Handle tray icon click events
  });

tauri::Builder::default()
  .on_menu_event(|app, event| {
    if event.id == quit_item_id {
      app.exit(0);
    }
  });
```

### 4.2 Exit Behavior
On quit:
1. Stop recording if in progress
2. Terminate Python backend
3. Clean up temp audio files
4. Close overlay window

## Phase 5: Settings UI

Create settings panel in `src/App.tsx`:

### Settings Fields
- **Hotkey**: Configurable shortcut (default: Ctrl+Shift+D)
- **Input Device**: Microphone selection
- **Whisper Model**: tiny/base/small (default: base)
- **Language**: auto/en/ru (default: auto)
- **Output Destination**: clipboard vs insert into active window (default: clipboard)

### Storage
- Settings stored in `tauri.conf.json` or local storage + config file
- Sync to Python backend config on change

## Phase 6: Packaging

### 6.1 Windows Packaging
1. Bundle Python backend with PyInstaller
2. Include model weights or download on first run
3. Create MSI or NSIS installer via Tauri bundler

### 6.2 Debian Packaging
1. Create `.deb` package
2. Install system dependencies:
   - `ffmpeg`
   - `python3`
   - `alsa-utils` or `pulseaudio` (for audio capture)
3. Post-install hooks to:
   - Download Whisper model weights
   - Set up Python virtual environment
   - Configure default hotkey

## Key Design Decisions

- **Overlay**: Always-on-top transparent window managed by Tauri
- **Hotkey**: Tauri global shortcut plugin
- **Backend**: Python for Whisper + audio capture
- **Packaging**: Tauri native installers (no Docker)
- **Service**: No OS-level daemon; app stays open in background

## Known Risks & Tradeoffs

| Risk | Mitigation |
|------|------------|
| Python bundling complexity | Use PyInstaller; test on both platforms |
| Overlay on Linux (GNOME/KDE) | Test on both DEs; add fallback to toast |
| Hotkey conflicts | Allow config UI to change keys |
| CPU inference latency | Allow user to select model (tiny/base/small) |
| Audio device permissions | Add clear error messages + config UI |
| Model download size | Stream on first run; show progress |

## Deliverables Checklist

### Core Features
- [ ] Overlay window with animation
- [ ] Global hotkey registration
- [ ] Recording state machine
- [ ] Python backend (audio + Whisper)
- [ ] IPC between Tauri and Python
- [ ] Tray icon + quit handler
- [ ] Settings UI

### Platform Support
- [ ] Windows installer (MSI/NSIS)
- [ ] Debian package (.deb)
- [ ] Audio capture working on both platforms
- [ ] Overlay rendering correctly on both platforms

### Polish
- [ ] Error handling with user-friendly messages
- [ ] Progress indicators (model download, processing)
- [ ] Keyboard shortcut customization
- [ ] First-run setup wizard

## Next Steps

1. **Tech Confirmation**: Finalize Tauri version (v2 preferred), decide HTTP vs stdin/stdout IPC
2. **Prototype**: Build minimal overlay + hotkey + mock backend to verify architecture
3. **Backend Integration**: Wire Python backend with real Whisper
4. **Packaging Proof**: Test bundling Python on Windows and Debian
5. **UX Polish**: Refine overlay animations and error states

## Notes from Research

- Tauri v2 uses `@tauri-apps/plugin-global-shortcut` for global hotkeys
- Window effects/transparency vary by OS; test Windows 11 and Debian
- Tray handling requires `tray-icon` feature in `Cargo.toml`
- Python backend should keep Whisper model in memory for performance

---

**Document Version**: 1.0  
**Created**: 2026-01-17
