#!/bin/bash
# Vercel build script for Flutter Web

echo "1. Downloading Flutter (stable branch)..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "2. Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "3. Initializing Flutter..."
flutter precache

echo "4. Getting packages..."
flutter pub get

echo "5. Building for Web..."
# Using html renderer for better compatibility, or you can use canvaskit
flutter build web --release --web-renderer canvaskit

echo "Build Complete!"
