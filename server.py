import json
import os
import tempfile
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

import transcribe

HOST = "0.0.0.0"
PORT = int(os.getenv("WHISPER_PORT", "8610"))
DEFAULT_LANGUAGE = transcribe.sanitize_language(os.getenv("WHISPER_LANG", "en"))
DEFAULT_OUTPUT_LANGUAGE = transcribe.sanitize_output_language(
    os.getenv("WHISPER_OUTPUT_LANG", "")
)


def json_response(handler, status_code, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status_code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


class TranscriptionHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/health"):
            json_response(self, 200, {"status": "ok"})
            return
        json_response(self, 404, {"error": "not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != "/transcribe":
            json_response(self, 404, {"error": "not found"})
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        if content_length <= 0:
            json_response(self, 400, {"error": "empty request"})
            return

        audio_bytes = self.rfile.read(content_length)
        query = parse_qs(parsed.query)
        language = transcribe.sanitize_language(
            query.get("language", [DEFAULT_LANGUAGE])[0],
            default=DEFAULT_LANGUAGE,
        )
        output_language = transcribe.sanitize_output_language(
            query.get("output_language", [DEFAULT_OUTPUT_LANGUAGE])[0]
        ) or DEFAULT_OUTPUT_LANGUAGE

        temp_path = None
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp:
                temp.write(audio_bytes)
                temp_path = temp.name

            text = transcribe.transcribe(
                temp_path,
                language=language,
                output_language=output_language,
                print_output=False,
            )
            json_response(self, 200, {"text": text})
        except Exception as exc:
            json_response(self, 500, {"error": str(exc)})
        finally:
            if temp_path and os.path.exists(temp_path):
                os.unlink(temp_path)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    transcribe.load_model()
    server = HTTPServer((HOST, PORT), TranscriptionHandler)
    print(f"Whisper daemon listening on {HOST}:{PORT}")
    server.serve_forever()
