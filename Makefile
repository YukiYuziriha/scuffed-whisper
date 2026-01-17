.PHONY: build run stop clean help setup enable-service disable-service

help:
	@echo "Available targets:"
	@echo "  setup          - Install dependencies"
	@echo "  build          - Build Docker image"
	@echo "  run            - Run container in background"
	@echo "  stop           - Stop container"
	@echo "  clean          - Remove container and image"
	@echo "  enable-service - Enable autostart service"
	@echo "  disable-service - Disable autostart service"
	@echo "  test           - Test transcription with sample audio"

setup:
	@echo "Run ./scripts/install.sh to install dependencies"

build:
	docker build -t voxtral-dictation .

run:
	docker run -d --name voxtral-app \
		-e HF_HUB_DISABLE_PROGRESS_BARS=1 \
		-v $(PWD)/recordings:/app/recordings:rw \
		-v $(PWD)/transcribe.py:/app/transcribe.py:ro \
		-v $(HOME)/.cache/huggingface:/root/.cache/huggingface:rw \
		voxtral-dictation sleep infinity

stop:
	docker stop voxtral-app || true
	docker rm voxtral-app || true

clean: stop
	docker rmi voxtral-dictation || true

test:
	docker run --rm \
		-e HF_HUB_DISABLE_PROGRESS_BARS=1 \
		-v $(PWD)/recordings:/app/recordings \
		-v $(PWD)/transcribe.py:/app/transcribe.py:ro \
		-v $(HOME)/.cache/huggingface:/root/.cache/huggingface:rw \
		voxtral-dictation python /app/transcribe.py /app/recordings/test.wav

enable-service:
	@./scripts/install-service.sh

disable-service:
	@./scripts/install-service.sh --disable
