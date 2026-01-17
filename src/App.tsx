import { useEffect, useState } from 'react'
import Overlay from './overlay/Overlay'
import Settings from './Settings'
import { createRecorderMachine, RecorderState, RecorderEvent } from './state/recorder'
import { registerShortcut } from './lib/hotkeys'
import { startRecording, stopRecording, transcribe, checkHealth } from './lib/api'
import { getCurrentWindow } from '@tauri-apps/api/window'

function App() {
  const [recorderState, setRecorderState] = useState<RecorderState>('idle')
  const [overlayVisible, setOverlayVisible] = useState(false)
  const [language, setLanguage] = useState('auto')
  const [backendHealthy, setBackendHealthy] = useState(false)
  const [settingsVisible, setSettingsVisible] = useState(false)

  useEffect(() => {
    const savedLanguage = localStorage.getItem('whisper-language') || 'auto'
    setLanguage(savedLanguage)
  }, [])

  useEffect(() => {
    const machine = createRecorderMachine()

    async function handleShortcut() {
      const event: RecorderEvent = { type: 'TOGGLE_RECORD' }
      const newState = machine.transition(event)
      setRecorderState(newState)

      if (newState === 'recording') {
        setOverlayVisible(true)
        try {
          await startRecording()
        } catch (error) {
          console.error('Failed to start recording:', error)
          machine.transition({ type: 'ERROR' })
          setRecorderState('error')
        }
      } else if (newState === 'processing') {
        try {
          const { audio_file } = await stopRecording()
          const result = await transcribe(audio_file, language)
          console.log('Transcription:', result.text)

          machine.transition({ type: 'PROCESSING_COMPLETE' })
          setRecorderState('idle')
          setOverlayVisible(false)
        } catch (error) {
          console.error('Transcription failed:', error)
          machine.transition({ type: 'ERROR' })
          setRecorderState('error')
          setTimeout(() => {
            machine.transition({ type: 'TOGGLE_RECORD' })
            setRecorderState('idle')
            setOverlayVisible(false)
          }, 2000)
        }
      }
    }

    async function setup() {
      const savedHotkey = localStorage.getItem('whisper-hotkey') || 'Ctrl+Shift+D'
      await registerShortcut(savedHotkey, handleShortcut)
      
      try {
        await checkHealth()
        setBackendHealthy(true)
      } catch (error) {
        console.error('Backend not healthy:', error)
      }

      const window = getCurrentWindow()
      await window.hide()
    }

    setup()

    return () => {
      registerShortcut('', () => {}).catch(console.error)
    }
  }, [language])

  return (
    <>
      <Overlay visible={overlayVisible} state={recorderState} />
      <Settings visible={settingsVisible} onClose={() => setSettingsVisible(false)} />
      <div style={{ padding: '20px', display: overlayVisible ? 'none' : 'block' }}>
        <h1>Whisper Dictation</h1>
        <p>Status: {backendHealthy ? 'Connected' : 'Disconnected'}</p>
        <p>Recorder: {recorderState}</p>
        <p>Language: {language}</p>
        <button onClick={() => setSettingsVisible(true)}>Settings</button>
      </div>
    </>
  )
}

export default App
