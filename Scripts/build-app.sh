#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$PROJECT_DIR/AppBundle/Info.plist"
APP_NAME="seifert-it Ausgaben"
EXECUTABLE_NAME="SeifertAusgaben"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/seifert-ausgaben.XXXXXX")"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
SCRATCH_DIR="$BUILD_DIR/swift-build"
MODULE_CACHE="$BUILD_DIR/module-cache"

if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]]; then
  export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
else
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
fi
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"
CONFIGURATION="${SWIFT_BUILD_CONFIGURATION:-release}"

cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT

cd "$PROJECT_DIR"
swift build -c "$CONFIGURATION" --disable-sandbox --scratch-path "$SCRATCH_DIR" -debug-info-format none --enable-experimental-strip-products
BIN_DIR="$(swift build -c "$CONFIGURATION" --disable-sandbox --scratch-path "$SCRATCH_DIR" -debug-info-format none --enable-experimental-strip-products --show-bin-path)"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$DIST_DIR"
ditto "$BIN_DIR/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
ditto "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
ditto "$PROJECT_DIR/Sources/SeifertAusgaben/Resources/Logo_seifert-it.jpg" "$APP_DIR/Contents/Resources/Logo_seifert-it.jpg"
if [[ -f "$PROJECT_DIR/AppBundle/AppIcon.icns" ]]; then
  ditto "$PROJECT_DIR/AppBundle/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"
ARCHIVE="$DIST_DIR/seifert-it-Ausgaben-macOS-v$VERSION.zip"
rm -f "$ARCHIVE"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE"
codesign --verify --deep --strict "$APP_DIR"
echo "Erstellt: $ARCHIVE"
