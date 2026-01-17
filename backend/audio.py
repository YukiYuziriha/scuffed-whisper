import wave
import threading
import queue
from pathlib import Path
from typing import Optional
import sys

try:
    import sounddevice as sd
    import soundfile as sf
    HAS_SOUNDDEVICE = True
except ImportError:
    HAS_SOUNDDEVICE = False
    print("sounddevice not available, using pyaudio fallback")

try:
    import pyaudio
    HAS_PYAUDIO = True
except ImportError:
    HAS_PYAUDIO = False

from .config import Config, get_config

class AudioRecorder:
    def __init__(self, config: Optional[Config] = None):
        self.config = config or get_config()
        self.recording = False
        self.audio_queue: queue.Queue[bytes] = queue.Queue()
        self.recording_thread: Optional[threading.Thread] = None
        self.frames = []
        self.stream = None

    def start_recording(self) -> Path:
        if self.recording:
            raise RuntimeError("Already recording")

        audio_file = self.config.get_audio_file("recording.wav")
        self.frames = []
        self.recording = True

        if HAS_SOUNDDEVICE:
            self._record_with_sounddevice(audio_file)
        elif HAS_PYAUDIO:
            self._record_with_pyaudio(audio_file)
        else:
            raise RuntimeError("No audio backend available. Install sounddevice or pyaudio.")

        return audio_file

    def _record_with_sounddevice(self, audio_file: Path):
        def callback(indata, frames, time, status):
            if status:
                print(f"Audio callback error: {status}", file=sys.stderr)
            self.audio_queue.put(indata.copy())

        try:
            self.stream = sd.InputStream(
                samplerate=self.config.sample_rate,
                channels=self.config.channels,
                callback=callback,
                dtype='float32'
            )
            self.stream.start()

            self.recording_thread = threading.Thread(target=self._write_file, args=(audio_file,))
            self.recording_thread.start()
        except Exception as e:
            self.recording = False
            raise RuntimeError(f"Failed to start recording: {e}")

    def _record_with_pyaudio(self, audio_file: Path):
        p = pyaudio.PyAudio()
        
        def record_thread():
            try:
                self.stream = p.open(
                    format=pyaudio.paInt16,
                    channels=self.config.channels,
                    rate=self.config.sample_rate,
                    input=True,
                    frames_per_buffer=1024
                )
                
                while self.recording:
                    data = self.stream.read(1024, exception_on_overflow=False)
                    self.frames.append(data)
                    
            finally:
                if self.stream:
                    self.stream.stop_stream()
                    self.stream.close()
                p.terminate()

        self.recording_thread = threading.Thread(target=record_thread)
        self.recording_thread.start()

    def _write_file(self, audio_file: Path):
        with sf.SoundFile(str(audio_file), mode='w', 
                          samplerate=self.config.sample_rate,
                          channels=self.config.channels) as file:
            while self.recording or not self.audio_queue.empty():
                try:
                    data = self.audio_queue.get(timeout=0.1)
                    file.write(data)
                except queue.Empty:
                    continue

    def stop_recording(self) -> Path:
        if not self.recording:
            raise RuntimeError("Not recording")

        self.recording = False
        
        if self.stream and HAS_SOUNDDEVICE:
            self.stream.stop()
            self.stream.close()

        if self.recording_thread:
            self.recording_thread.join(timeout=5)

        return self.config.get_audio_file("recording.wav")

    def is_recording(self) -> bool:
        return self.recording
