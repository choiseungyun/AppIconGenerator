#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/integration-tests"
BIN_PATH="$BUILD_DIR/appicon-integration-tests"

mkdir -p "$BUILD_DIR"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

echo "[1/2] Building integration test binary"
swiftc \
  "$PROJECT_ROOT/AppIconGeneratorApp/IconSpecs.swift" \
  "$PROJECT_ROOT/AppIconGeneratorApp/GenerationLogEntry.swift" \
  "$PROJECT_ROOT/AppIconGeneratorApp/AppLanguage.swift" \
  "$PROJECT_ROOT/AppIconGeneratorApp/IconGenerator.swift" \
  "$PROJECT_ROOT/AppIconGeneratorApp/StoreAssetSpecs.swift" \
  "$PROJECT_ROOT/AppIconGeneratorApp/StoreAssetGenerator.swift" \
  "$PROJECT_ROOT/IntegrationTests/main.swift" \
  -sdk "$SDK_PATH" \
  -o "$BIN_PATH"

echo "[2/2] Running integration tests"
"$BIN_PATH"
