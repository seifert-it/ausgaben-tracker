#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$PROJECT_DIR/AppBundle/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
DIST_DIR="$PROJECT_DIR/dist"
APP_ARCHIVE="$DIST_DIR/seifert-it-Ausgaben-macOS-v$VERSION.zip"
DMG_PATH="$DIST_DIR/seifert-it-Ausgaben-v$VERSION.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/seifert-ausgaben-dmg.XXXXXX")"

cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

"$PROJECT_DIR/Scripts/build-app.sh"
ditto -x -k "$APP_ARCHIVE" "$STAGING_DIR"
ln -s /Applications "$STAGING_DIR/Programme"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "seifert-it Ausgaben" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov "$DMG_PATH"
hdiutil verify "$DMG_PATH"
echo "Erstellt: $DMG_PATH"
