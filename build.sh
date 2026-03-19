#!/bin/bash

# 1. Install Flutter if not already there
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add Flutter to the Path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable web support and build
flutter config --enable-web
flutter pub get
flutter build web --release --wasm-renderer=html