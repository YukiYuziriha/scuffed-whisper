import { useState, useEffect } from 'react'
import './settings.css'

interface SettingsProps {
  visible: boolean
  onClose: () => void
}

function Settings({ visible, onClose }: SettingsProps) {
  const [language, setLanguage] = useState('auto')
  const [hotkey, setHotkey] = useState('Ctrl+Shift+D')
  const [model, setModel] = useState('base')

  useEffect(() => {
    if (visible) {
      const savedLanguage = localStorage.getItem('whisper-language') || 'auto'
      const savedHotkey = localStorage.getItem('whisper-hotkey') || 'Ctrl+Shift+D'
      const savedModel = localStorage.getItem('whisper-model') || 'base'

      setLanguage(savedLanguage)
      setHotkey(savedHotkey)
      setModel(savedModel)
    }
  }, [visible])

  const handleSave = () => {
    localStorage.setItem('whisper-language', language)
    localStorage.setItem('whisper-hotkey', hotkey)
    localStorage.setItem('whisper-model', model)
    onClose()
  }

  if (!visible) return null

  return (
    <div className="settings-overlay" onClick={onClose}>
      <div className="settings-panel" onClick={(e) => e.stopPropagation()}>
        <div className="settings-header">
          <h2>Settings</h2>
          <button className="close-button" onClick={onClose}>×</button>
        </div>

        <div className="settings-content">
          <div className="setting-group">
            <label htmlFor="language">Language</label>
            <select
              id="language"
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
            >
              <option value="auto">Auto-detect</option>
              <option value="en">English</option>
              <option value="ru">Russian</option>
            </select>
          </div>

          <div className="setting-group">
            <label htmlFor="hotkey">Hotkey</label>
            <input
              id="hotkey"
              type="text"
              value={hotkey}
              onChange={(e) => setHotkey(e.target.value)}
              placeholder="Ctrl+Shift+D"
            />
          </div>

          <div className="setting-group">
            <label htmlFor="model">Whisper Model</label>
            <select
              id="model"
              value={model}
              onChange={(e) => setModel(e.target.value)}
            >
              <option value="tiny">Tiny (fastest, less accurate)</option>
              <option value="base">Base (balanced)</option>
              <option value="small">Small (slower, more accurate)</option>
            </select>
          </div>
        </div>

        <div className="settings-footer">
          <button className="cancel-button" onClick={onClose}>Cancel</button>
          <button className="save-button" onClick={handleSave}>Save</button>
        </div>
      </div>
    </div>
  )
}

export default Settings
