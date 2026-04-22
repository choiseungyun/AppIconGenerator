#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AppIconGenerator"
APP_PATH="$PROJECT_ROOT/build/DerivedData/Build/Products/Release/${APP_NAME}.app"
DMG_PATH=""
IDENTITY=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --app PATH         Path to .app to sign
  --dmg PATH         Optional .dmg path to sign
  --identity NAME    Signing identity display name (exact match)
  -h, --help         Show this help

Examples:
  ./scripts/sign-app.sh
  ./scripts/sign-app.sh --app build/DerivedData/Build/Products/Release/AppIconGenerator.app
  ./scripts/sign-app.sh --dmg dist/AppIconGenerator.dmg
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_PATH="$2"
      shift 2
      ;;
    --dmg)
      DMG_PATH="$2"
      shift 2
      ;;
    --identity)
      IDENTITY="$2"
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

cd "$PROJECT_ROOT"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: app not found: $APP_PATH"
  exit 1
fi

if [[ -z "$IDENTITY" ]]; then
  # Prefer Developer ID Application for outside-App-Store distribution.
  IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -n 1 || true)"

  # Fallback to Apple Development for local/test signing.
  if [[ -z "$IDENTITY" ]]; then
    IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development:.*\)"/\1/p' | head -n 1 || true)"
  fi
fi

if [[ -z "$IDENTITY" ]]; then
  echo "Error: no code signing identity found."
  echo "Install certificate in Keychain and retry."
  exit 1
fi

SIGN_ARGS=(--force --deep --sign "$IDENTITY")

if [[ "$IDENTITY" == Developer\ ID\ Application:* ]]; then
  SIGN_ARGS+=(--options runtime --timestamp)
else
  echo "Warning: using Apple Development identity."
  echo "For external distribution, use 'Developer ID Application' + notarization."
fi

echo "Signing app with identity: $IDENTITY"
codesign "${SIGN_ARGS[@]}" "$APP_PATH"

echo "Verifying app signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

# Gatekeeper assessment can fail for non-notarized builds; show output for visibility.
echo "Gatekeeper assessment"
spctl -a -vv "$APP_PATH" || true

if [[ -n "$DMG_PATH" ]]; then
  if [[ ! -f "$DMG_PATH" ]]; then
    echo "Error: dmg not found: $DMG_PATH"
    exit 1
  fi

  echo "Signing dmg with identity: $IDENTITY"
  codesign --force --sign "$IDENTITY" "$DMG_PATH"

  echo "Verifying dmg signature"
  codesign --verify --verbose=2 "$DMG_PATH"
  spctl -a -vv "$DMG_PATH" || true
fi

echo "Done"
