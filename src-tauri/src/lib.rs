use tauri::menu::{MenuBuilder, MenuItemBuilder};
use tauri::tray::{TrayIconBuilder, TrayIconEvent};
use tauri::Manager;
use std::process::{Command, Child, Stdio};
use std::sync::{Arc, Mutex};

struct BackendProcess {
    child: Option<Child>,
}

impl BackendProcess {
    fn new() -> Self {
        Self { child: None }
    }

    fn start(&mut self) -> Result<(), String> {
        if self.child.is_some() {
            return Err("Backend already running".to_string());
        }

        let python = std::env::var("PYTHON_PATH").unwrap_or_else(|_| "python3".to_string());
        let backend_path = std::path::PathBuf::from("backend/main.py");
        let backend_path = if backend_path.is_absolute() {
            backend_path
        } else {
            std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("backend/main.py")
        };

        let child = Command::new(&python)
            .arg(&backend_path)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| format!("Failed to start backend: {}", e))?;

        self.child = Some(child);
        Ok(())
    }

    fn stop(&mut self) -> Result<(), String> {
        if let Some(mut child) = self.child.take() {
            child.kill().map_err(|e| format!("Failed to stop backend: {}", e))?;
            child.wait().ok();
        }
        Ok(())
    }
}

impl Drop for BackendProcess {
    fn drop(&mut self) {
        let _ = self.stop();
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .plugin(tauri_plugin_global_shortcut::Builder::new().build())
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }

      let backend = Arc::new(Mutex::new(BackendProcess::new()));

      let mut backend_guard = backend.lock().unwrap();
      if let Err(e) = backend_guard.start() {
        eprintln!("Warning: Failed to start Python backend: {}", e);
      }
      drop(backend_guard);

      let quit_item = MenuItemBuilder::new("Quit").id("quit").build(app)?;
      let show_item = MenuItemBuilder::new("Show").id("show").build(app)?;
      let menu = MenuBuilder::new(app)
        .items(&[&show_item, &quit_item])
        .build()?;

      let tray = TrayIconBuilder::new()
        .menu(&menu)
        .tooltip("Whisper Dictation")
        .build(app)?;

      let show_window = show_item.clone();
      let quit_app = quit_item.clone();
      let backend_clone = Arc::clone(&backend);
      app.on_menu_event(move |app, event| {
        if event.id == quit_app.id() {
          let mut backend_guard = backend_clone.lock().unwrap();
          let _ = backend_guard.stop();
          app.exit(0);
        } else if event.id == show_window.id() {
          if let Some(window) = app.get_webview_window("main") {
            let _ = window.show();
          }
        }
      });

      let app_handle = app.handle().clone();
      app.on_tray_icon_event(|tray, event| {
        if let TrayIconEvent::Click {
          button: tauri::tray::MouseButton::Left,
          ..
        } = event
        {
          if let Some(window) = tray.app_handle().get_webview_window("main") {
            let _ = window.show();
            let _ = window.set_focus();
          }
        }
      });

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
