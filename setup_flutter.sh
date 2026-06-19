#!/bin/bash
set -e

SDK_DIR="/home/kynguyen/flutter-sdk"

echo "=== 1. Cloning Flutter SDK ==="
if [ ! -d "$SDK_DIR" ]; then
    echo "Cloning Flutter stable branch to $SDK_DIR..."
    git clone https://github.com/flutter/flutter.git -b stable "$SDK_DIR"
else
    echo "Flutter SDK already exists at $SDK_DIR. Updating repository..."
    cd "$SDK_DIR" && git pull
fi

# Add Flutter to current path
export PATH="$PATH:$SDK_DIR/bin"

echo "=== 2. Installing Linux Dependencies ==="
echo "This requires sudo to install development tools (clang, ninja, gtk3 dev, lzma dev)..."
sudo apt-get update
sudo apt-get install -y clang ninja-build libgtk-3-dev liblzma-dev pkg-config

echo "=== 3. Pre-loading Flutter Artifacts & Checking Doctor ==="
flutter doctor

echo "=== Flutter Setup Finished Successfully! ==="
