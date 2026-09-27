#!/bin/bash
set -e  # Exit immediately if any command fails

echo "==> Step 1: Cloning Flutter stable..."
git clone https://github.com/flutter/flutter.git --branch stable --depth 1 flutter-sdk

echo "==> Step 2: Adding Flutter to PATH..."
export PATH="$PATH:$(pwd)/flutter-sdk/bin"

echo "==> Step 3: Verifying Flutter..."
flutter --version

echo "==> Step 4: Disabling analytics..."
flutter config --no-analytics

echo "==> Step 5: Getting dependencies..."
flutter pub get

echo "==> Step 6: Building Flutter Web (CanvasKit)..."
flutter build web --release --web-renderer canvaskit

echo "==> BUILD COMPLETE. Output is in: $(pwd)/build/web"
ls build/web

