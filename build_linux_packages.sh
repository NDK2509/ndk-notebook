#!/bin/bash
set -e

# Configuration
APP_NAME="ndk-notebook"
FLUTTER_BIN="$HOME/flutter-sdk/bin/flutter"
PROJECT_ROOT="$(pwd)"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build/packages"
TEMP_BUILD_DIR="$PROJECT_ROOT/build/packaging_temp"

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '\r' | tr -d '"' | tr -d "'")
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi
echo "Version to build: $VERSION"


echo "=================================================="
echo "    Packaging NDK Notebook (.deb & .AppImage)     "
echo "=================================================="

# 1. Ensure Flutter is built in release mode
echo "[1/4] Building Flutter project in release mode..."
if [ ! -f "$FLUTTER_BIN" ]; then
    echo "Error: Flutter SDK not found at $FLUTTER_BIN"
    echo "Please configure FLUTTER_BIN in this script to point to your flutter executable."
    exit 1
fi

$FLUTTER_BIN build linux --release

# Find the build binary name (usually matches pubspec.yaml name: flutter_desktop_demo)
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Release bundle directory not found at $BUNDLE_DIR"
    exit 1
fi

# 2. Setup output folder
mkdir -p "$BUILD_OUTPUT_DIR"
rm -rf "$TEMP_BUILD_DIR"
mkdir -p "$TEMP_BUILD_DIR"

# 3. Build Debian (.deb) Package
echo -e "\n[2/4] Packaging to Debian (.deb)..."
DEB_DIR="$TEMP_BUILD_DIR/deb"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"

# Copy Flutter release bundle files
cp -r "$BUNDLE_DIR"/* "$DEB_DIR/usr/share/$APP_NAME/"

# Copy Icon
if [ -f "$PROJECT_ROOT/web/icons/Icon-512.png" ]; then
    cp "$PROJECT_ROOT/web/icons/Icon-512.png" "$DEB_DIR/usr/share/pixmaps/$APP_NAME.png"
fi

# Create launcher script
cat << 'EOF' > "$DEB_DIR/usr/bin/$APP_NAME"
#!/bin/sh
# Get directory of the script
exec /usr/share/ndk-notebook/flutter_desktop_demo "$@"
EOF
chmod +x "$DEB_DIR/usr/bin/$APP_NAME"

# Create .desktop file
cat << EOF > "$DEB_DIR/usr/share/applications/$APP_NAME.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=NDK Notebook
Comment=A powerful, modern desktop note-taking application.
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=Office;Utility;
EOF

# Create Debian control file
cat << EOF > "$DEB_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Architecture: amd64
Maintainer: NDK Developer <ndk@example.com>
Depends: libgtk-3-0, liblzma5, libglib2.0-0
Description: NDK Notebook
 A beautiful, modern desktop hierarchical note-taking application.
EOF

# Build DEB
dpkg-deb --build "$DEB_DIR" "$BUILD_OUTPUT_DIR/${APP_NAME}_${VERSION}_amd64.deb"
echo "Success: Debian package created at $BUILD_OUTPUT_DIR/${APP_NAME}_${VERSION}_amd64.deb"


# 4. Build AppImage
echo -e "\n[3/4] Packaging to AppImage..."
APPDIR="$TEMP_BUILD_DIR/AppDir"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/$APP_NAME"

# Copy Flutter release bundle files
cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/share/$APP_NAME/"

# Copy Launcher and Desktop entries
cat << 'EOF' > "$APPDIR/usr/bin/$APP_NAME"
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/../share/ndk-notebook/flutter_desktop_demo" "$@"
EOF
chmod +x "$APPDIR/usr/bin/$APP_NAME"

# Create main AppRun file at root of AppDir
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/ndk-notebook" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Copy desktop file and icon to root of AppDir
cat << EOF > "$APPDIR/$APP_NAME.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=NDK Notebook
Comment=A powerful, modern desktop note-taking application.
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=Office;Utility;
EOF

if [ -f "$PROJECT_ROOT/web/icons/Icon-512.png" ]; then
    cp "$PROJECT_ROOT/web/icons/Icon-512.png" "$APPDIR/$APP_NAME.png"
fi

# Download/locate appimagetool
APPIMAGE_TOOL="$PROJECT_ROOT/build/appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGE_TOOL" ]; then
    echo "Downloading appimagetool..."
    curl -L -o "$APPIMAGE_TOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGE_TOOL"
fi

# Build AppImage
echo "Generating AppImage using appimagetool..."
ARCH=x86_64 "$APPIMAGE_TOOL" "$APPDIR" "$BUILD_OUTPUT_DIR/NDK_Notebook-${VERSION}-x86_64.AppImage"
echo "Success: AppImage package created at $BUILD_OUTPUT_DIR/NDK_Notebook-${VERSION}-x86_64.AppImage"

# Clean up temp
rm -rf "$TEMP_BUILD_DIR"

echo -e "\n[4/4] Done! All packages generated inside $BUILD_OUTPUT_DIR"
ls -lh "$BUILD_OUTPUT_DIR"
