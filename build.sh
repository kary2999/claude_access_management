#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Installing xcodegen via brew…"
  brew install xcodegen
fi

xcodegen generate

xcodebuild -project ClaudeAccessManagement.xcodeproj \
  -scheme ClaudeAccessManagement \
  -configuration Release \
  -destination 'platform=macOS' \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  clean build

APP=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "ClaudeAccessManagement.app" -path "*/Release/*" | head -1)
echo
echo "Built: $APP"
echo "Run:   open \"$APP\""
