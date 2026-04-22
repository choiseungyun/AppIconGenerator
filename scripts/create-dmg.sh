#!/usr/bin/env bash
set -euo pipefail

APP_NAME="AppIconGenerator"
SCHEME="AppIconGenerator"
CONFIGURATION="Release"
PROJECT_PATH="AppIconGenerator.xcodeproj"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$PROJECT_ROOT/build/DerivedData"
OUTPUT_DIR="$PROJECT_ROOT/dist"
STAGING_DIR="$PROJECT_ROOT/build/dmg-root"
DMG_PATH="$OUTPUT_DIR/${APP_NAME}.dmg"
SHOULD_BUILD=true
XCODEBUILD_BIN="xcodebuild"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --no-build           Skip xcodebuild step and package existing .app
  --scheme NAME        Xcode scheme name (default: ${SCHEME})
  --project PATH       Xcode project path relative to project root (default: ${PROJECT_PATH})
  --configuration CFG  Build configuration (default: ${CONFIGURATION})
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)
      SHOULD_BUILD=false
      shift
      ;;
    --scheme)
      SCHEME="$2"
      shift 2
      ;;
    --project)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "Error: create-dmg is not installed."
  echo "Install: brew install create-dmg"
  exit 1
fi

if command -v xcodebuild >/dev/null 2>&1; then
  if ! xcodebuild -version >/dev/null 2>&1; then
    if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
      XCODEBUILD_BIN="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
    else
      echo "Error: xcodebuild requires full Xcode, not only Command Line Tools."
      echo "Set once: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
      exit 1
    fi
  fi
elif [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
  XCODEBUILD_BIN="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
else
  echo "Error: xcodebuild is not available."
  exit 1
fi

cd "$PROJECT_ROOT"

if [[ "$SHOULD_BUILD" == true ]]; then
  echo "[1/3] Building ${APP_NAME}.app (${CONFIGURATION})"
  "$XCODEBUILD_BIN" \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
fi

APP_PATH="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: app not found at ${APP_PATH}"
  echo "Run without --no-build or verify scheme/configuration."
  exit 1
fi

echo "[2/3] Preparing DMG staging files"
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR" "$OUTPUT_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

echo "[3/3] Creating DMG"
create-dmg \
  --volname "$APP_NAME" \
  --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 680 420 \
  --icon-size 120 \
  --icon "$APP_NAME.app" 180 210 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 500 210 \
  "$DMG_PATH" \
  "$STAGING_DIR"

echo "Done: $DMG_PATH"
