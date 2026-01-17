export type RecorderState = 'idle' | 'recording' | 'processing' | 'error'

export type RecorderEvent =
  | { type: 'TOGGLE_RECORD' }
  | { type: 'START_RECORD' }
  | { type: 'STOP_RECORD' }
  | { type: 'PROCESSING_START' }
  | { type: 'PROCESSING_COMPLETE' }
  | { type: 'ERROR' }

interface RecorderContext {
  state: RecorderState
  transition: (event: RecorderEvent) => RecorderState
}

export function createRecorderMachine(): RecorderContext {
  let currentState: RecorderState = 'idle'

  function transition(event: RecorderEvent): RecorderState {
    const nextState = getNextState(currentState, event)
    currentState = nextState
    return nextState
  }

  return {
    state: currentState,
    transition,
  }
}

function getNextState(current: RecorderState, event: RecorderEvent): RecorderState {
  switch (current) {
    case 'idle':
      if (event.type === 'START_RECORD' || event.type === 'TOGGLE_RECORD') {
        return 'recording'
      }
      return current

    case 'recording':
      if (event.type === 'STOP_RECORD' || event.type === 'TOGGLE_RECORD') {
        return 'processing'
      }
      if (event.type === 'ERROR') {
        return 'error'
      }
      return current

    case 'processing':
      if (event.type === 'PROCESSING_COMPLETE') {
        return 'idle'
      }
      if (event.type === 'ERROR') {
        return 'error'
      }
      return current

    case 'error':
      if (event.type === 'START_RECORD') {
        return 'recording'
      }
      if (event.type === 'TOGGLE_RECORD') {
        return 'idle'
      }
      return current

    default:
      return current
  }
}
