.PHONY: build run stop clean help setup enable-service disable-service daemon daemon-stop

WHISPER_MODEL ?= openai/whisper-base
WHISPER_LANG ?= en
WHISPER_OUTPUT_LANG ?=
WHISPER_PORT ?= 8610

help:
	@echo "Available targets:"
	@echo "  setup          - Install dependencies"
	@echo "  build          - Build Docker image"
	@echo "  run            - Run container in background"
	@echo "  stop           - Stop container"
	@echo "  clean          - Remove container and image"
	@echo "  enable-service - Enable autostart service"
	@echo "  disable-service - Disable autostart service"
	@echo "  daemon         - Start daemon in container"
	@echo "  daemon-stop    - Stop daemon in container"
	@echo "  test           - Test transcription with sample audio"

setup:
	@echo "Run ./scripts/install.sh to install dependencies"

build:
	docker build -t whisper-dictation .

run:
	docker run -d --name whisper-app \
		-e HF_HUB_DISABLE_PROGRESS_BARS=1 \
		-e WHISPER_MODEL=$(WHISPER_MODEL) \
		-e WHISPER_LANG=$(WHISPER_LANG) \
		-e WHISPER_OUTPUT_LANG=$(WHISPER_OUTPUT_LANG) \
		-e WHISPER_PORT=$(WHISPER_PORT) \
		-p 127.0.0.1:$(WHISPER_PORT):$(WHISPER_PORT) \
		-v $(PWD)/recordings:/app/recordings:rw \
		-v $(PWD)/transcribe.py:/app/transcribe.py:ro \
		-v $(PWD)/server.py:/app/server.py:ro \
		-v $(HOME)/.cache/huggingface:/root/.cache/huggingface:rw \
		whisper-dictation sleep infinity

stop:
	docker stop whisper-app || true
	docker rm whisper-app || true

clean: stop
	docker rmi whisper-dictation || true

daemon:
	docker exec -d -e WHISPER_LANG=$(WHISPER_LANG) -e WHISPER_OUTPUT_LANG=$(WHISPER_OUTPUT_LANG) -e WHISPER_MODEL=$(WHISPER_MODEL) -e WHISPER_PORT=$(WHISPER_PORT) whisper-app python /app/server.py

daemon-stop:
	docker exec whisper-app pkill -f "/app/server.py" || true

test:
	docker run --rm \
		-e HF_HUB_DISABLE_PROGRESS_BARS=1 \
		-v $(PWD)/recordings:/app/recordings \
		-v $(PWD)/transcribe.py:/app/transcribe.py:ro \
		-v $(HOME)/.cache/huggingface:/root/.cache/huggingface:rw \
		whisper-dictation python /app/transcribe.py /app/recordings/test.wav

enable-service:
	@./scripts/install-service.sh

disable-service:
	@./scripts/install-service.sh --disable
