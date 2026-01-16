#!/bin/bash

# 1. Clone Flutter
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web
flutter config --enable-web

# 4. Get dependencies
echo "Getting dependencies..."
flutter pub get

# 5. Build Web
echo "Building for Web..."
flutter build web --release

echo "Build complete!"
