#!/bin/bash

# Path to the Flutter SDK we installed
FLUTTER_BIN="$HOME/flutter-sdk/bin/flutter"

echo "=========================================="
echo "         NDK Notebook App Runner          "
echo "=========================================="
echo "Select the target environment to run on:"
echo "1) Web (Chrome)       - [Recommended: Instant launch, zero-setup]"
echo "2) Linux Desktop      - [Requires clang, ninja-build, and GTK3 dev libs]"
echo "3) Android Emulator   - [Requires running emulator or connected device]"
echo "------------------------------------------"
read -p "Enter your choice [1-3] (Default is 1): " choice

# Default to choice 1 if empty
choice=${choice:-1}

case $choice in
    1)
        echo "Launching NDK Notebook in Web Mode (Chrome)..."
        $FLUTTER_BIN run -d chrome
        ;;
    2)
        echo "Verifying Linux desktop build tools..."
        if ! which clang >/dev/null 2>&1 || ! which ninja >/dev/null 2>&1; then
            echo -e "\n[Warning] clang or ninja is not found on your system."
            echo "To compile natively, make sure you have run:"
            echo "  sudo apt-get update && sudo apt-get install -y clang ninja-build libgtk-3-dev liblzma-dev pkg-config"
            echo ""
            read -p "Would you like to try compiling anyway? (y/N): " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                echo "Exiting. We recommend using Option 1 (Web) or installing the dependencies."
                exit 1
            fi
        fi
        echo "Launching NDK Notebook natively as a Linux Desktop App..."
        $FLUTTER_BIN run -d linux
        ;;
    3)
        echo "Launching NDK Notebook on Android device/emulator..."
        $FLUTTER_BIN run -d android
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
