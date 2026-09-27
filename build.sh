#!/bin/bash
set -e

echo "==> Step 1: Cloning Flutter stable..."
git clone https://github.com/flutter/flutter.git --branch stable --depth 1 flutter-sdk

echo "==> Step 2: Adding Flutter to PATH..."
export PATH="$PATH:$(pwd)/flutter-sdk/bin"

echo "==> Step 3: Verifying Flutter..."
flutter --version --suppress-analytics

echo "==> Step 4: Disabling analytics..."
flutter config --no-analytics --suppress-analytics

echo "==> Step 5: Getting dependencies..."
flutter pub get --suppress-analytics

echo "==> Step 6: Building Flutter Web..."
flutter build web --release --suppress-analytics

echo "==> BUILD COMPLETE. Output:"
ls -la build/web

