const BACKEND_URL = 'http://127.0.0.1:8610'

export interface TranscriptionResponse {
  text: string
  language?: string
  duration?: number
}

export interface ErrorResponse {
  error: string
  message?: string
}

export async function startRecording(): Promise<{ status: string }> {
  const response = await fetch(`${BACKEND_URL}/record/start`, {
    method: 'POST',
  })
  if (!response.ok) {
    throw new Error('Failed to start recording')
  }
  return response.json()
}

export async function stopRecording(): Promise<{ audio_file: string }> {
  const response = await fetch(`${BACKEND_URL}/record/stop`, {
    method: 'POST',
  })
  if (!response.ok) {
    throw new Error('Failed to stop recording')
  }
  return response.json()
}

export async function transcribe(audioFile: string, language: string = 'auto'): Promise<TranscriptionResponse> {
  const formData = new FormData()
  formData.append('audio_file', audioFile)
  if (language !== 'auto') {
    formData.append('language', language)
  }

  const response = await fetch(`${BACKEND_URL}/transcribe`, {
    method: 'POST',
    body: formData,
  })

  if (!response.ok) {
    const error: ErrorResponse = await response.json()
    throw new Error(error.message || 'Transcription failed')
  }

  return response.json()
}

export async function checkHealth(): Promise<{ status: string }> {
  const response = await fetch(`${BACKEND_URL}/health`)
  if (!response.ok) {
    throw new Error('Backend not healthy')
  }
  return response.json()
}
