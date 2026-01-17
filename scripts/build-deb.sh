#!/bin/bash

set -e

echo "Building Whisper Dictation for Debian..."

# Build frontend
echo "Building frontend..."
npm run build

# Build Tauri app (deb package)
echo "Building Debian package..."
npm run tauri build -- --target deb

echo "Build complete! .deb package is in src-tauri/target/release/bundle/deb/"
