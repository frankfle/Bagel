#!/bin/bash
set -e

APP_NAME="Bagel"
SCHEME="Bagel"
WORKSPACE="mac/Bagel.xcworkspace"
ARCHIVE_PATH="/tmp/${APP_NAME}.xcarchive"
EXPORT_PATH="/tmp/${APP_NAME}-exported"
DMG_PATH="$(pwd)/dist/${APP_NAME}.dmg"
APP_BUNDLE="${EXPORT_PATH}/${APP_NAME}.app"

# Optional: set these via environment or skip code signing/notarization
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
PROVISIONING_PROFILE="${PROVISIONING_PROFILE:-}"
NOTARIZE="${NOTARIZE:-0}"
NOTARIZATION_APPLE_ID="${NOTARIZATION_APPLE_ID:-}"
NOTARIZATION_PASSWORD="${NOTARIZATION_PASSWORD:-}"
NOTARIZATION_TEAM_ID="${NOTARIZATION_TEAM_ID:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[DMG]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Clean previous artifacts
log "Cleaning up previous artifacts..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p dist

# Step 1: Archive
log "Building archive..."
XCODEBUILD_ARGS=(
  -workspace "$WORKSPACE"
  -scheme "$SCHEME"
  -configuration Release
  clean
  archive
  -archivePath "$ARCHIVE_PATH"
)

if [ -n "$CODE_SIGN_IDENTITY" ]; then
  XCODEBUILD_ARGS+=(
    CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY"
  )
fi

if [ -n "$PROVISIONING_PROFILE" ]; then
  XCODEBUILD_ARGS+=(
    PROVISIONING_PROFILE="$PROVISIONING_PROFILE"
  )
fi

xcodebuild "${XCODEBUILD_ARGS[@]}" \
  || fail "Archive failed"

# Step 2: Export
log "Exporting app..."
EXPORT_ARGS=(
  -exportArchive
  -archivePath "$ARCHIVE_PATH"
  -exportPath "$EXPORT_PATH"
  -exportOptionsPlist "mac/ExportOptions.plist"
)

if [ -n "$CODE_SIGN_IDENTITY" ]; then
  EXPORT_ARGS+=(
    -exportSignPassword=""
  )
fi

xcodebuild "${EXPORT_ARGS[@]}" \
  || fail "Export failed"

if [ ! -d "$APP_BUNDLE" ]; then
  fail "App bundle not found at $APP_BUNDLE"
fi
log "App exported: $APP_BUNDLE"

# Step 3: Notarize (optional)
if [ "$NOTARIZE" = "1" ] && [ -n "$NOTARIZATION_APPLE_ID" ] && [ -n "$NOTARIZATION_PASSWORD" ] && [ -n "$NOTARIZATION_TEAM_ID" ]; then
  log "Notarizing app..."
  xcrun notarytool submit "$APP_BUNDLE" \
    --apple-id "$NOTARIZATION_APPLE_ID" \
    --password "$NOTARIZATION_PASSWORD" \
    --team-id "$NOTARIZATION_TEAM_ID" \
    --wait \
    || warn "Notarization failed"
  
  log "Stapling notarization ticket..."
  xcrun stapler staple "$APP_BUNDLE" || warn "Stapling failed"
else
  if [ "$NOTARIZE" = "1" ]; then
    warn "Notarization enabled but credentials not set. Skipping."
  fi
fi

# Step 4: Create DMG
log "Creating DMG..."

if command -v create-dmg &> /dev/null; then
  log "Using create-dmg for DMG creation"
  # Build create-dmg args
  CREATE_DMG_ARGS=(
    --volname "$APP_NAME"
    --window-size 500 350
    --icon "$APP_NAME.app" 130 140
    --app-drop-link 360 140
    "$DMG_PATH"
    "$EXPORT_PATH/"
  )

  # Optional background image
  if [ -n "$DMG_BACKGROUND" ]; then
    CREATE_DMG_ARGS+=(--background "$DMG_BACKGROUND")
  fi

  create-dmg "${CREATE_DMG_ARGS[@]}"
else
  warn "create-dmg not found (brew install create-dmg). Using hdiutil..."

  VOLUME_NAME="$APP_NAME"
  DMG_TEMP="/tmp/${APP_NAME}-temp.dmg"
  CONTENT_DIR="/tmp/${APP_NAME}-dmg-content"
  rm -rf "$CONTENT_DIR"
  mkdir -p "$CONTENT_DIR"
  cp -R "$APP_BUNDLE" "$CONTENT_DIR/"

  # Create symlink to /Applications for easy install
  ln -s /Applications "$CONTENT_DIR/Applications"

  # Create the DMG
  hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$CONTENT_DIR" \
    -ov \
    -format UDZO \
    "$DMG_TEMP" \
    || fail "hdiutil create failed"

  mv "$DMG_TEMP" "$DMG_PATH"
  rm -rf "$CONTENT_DIR"
fi

# Cleanup
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

log "Done! DMG created at: $DMG_PATH"
