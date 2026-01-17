import './overlay.css'

interface OverlayProps {
  visible: boolean
  state: 'idle' | 'recording' | 'processing' | 'error'
}

export default function Overlay({ visible, state }: OverlayProps) {
  if (!visible) return null

  return (
    <div className={`overlay overlay-${state}`}>
      <div className="overlay-content">
        <div className="mic-icon">
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 1C10.3431 1 9 2.34315 9 4V10C9 11.6569 10.3431 13 12 13C13.6569 13 15 11.6569 15 10V4C15 2.34315 13.6569 1 12 1Z" fill="currentColor" />
            <path d="M19 10V10C19 14.4183 15.4183 18 11 18H13C17.4183 18 21 14.4183 21 10V10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            <path d="M12 21V18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            <path d="M8 21H16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          </svg>
        </div>
        <div className="status-text">
          {state === 'recording' && 'Recording...'}
          {state === 'processing' && 'Processing...'}
          {state === 'error' && 'Error'}
        </div>
      </div>
      <div className="pulse-ring"></div>
    </div>
  )
}
