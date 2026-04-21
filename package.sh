#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClaudeAccessManagement"
VERSION="1.0.0"
BUILD="1"
BUNDLE_ID="com.local.ClaudeAccessManagement"
SDK=$(xcrun --sdk macosx --show-sdk-path)
DIST="dist"
APP="$DIST/${APP_NAME}.app"

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SOURCES=$(find Sources -name "*.swift" | sort)

compile_arch() {
  local arch="$1" out="$2"
  # shellcheck disable=SC2086
  swiftc -Onone -target "${arch}-apple-macos13.0" -sdk "$SDK" \
    -parse-as-library \
    -module-name "$APP_NAME" \
    -o "$out" \
    $SOURCES
}

echo "→ compile arm64"
compile_arch arm64   "$DIST/${APP_NAME}.arm64"
echo "→ compile x86_64"
compile_arch x86_64  "$DIST/${APP_NAME}.x86_64"

echo "→ lipo universal"
lipo -create -output "$APP/Contents/MacOS/${APP_NAME}" \
  "$DIST/${APP_NAME}.arm64" "$DIST/${APP_NAME}.x86_64"
rm "$DIST/${APP_NAME}.arm64" "$DIST/${APP_NAME}.x86_64"
chmod +x "$APP/Contents/MacOS/${APP_NAME}"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>Claude Access Manager</string>
  <key>CFBundleExecutable</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Claude Access Manager</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD}</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026</string>
</dict></plist>
PLIST

cat > "$APP/Contents/PkgInfo" <<<"APPL????"

echo "→ ad-hoc sign"
codesign --force --deep --sign - "$APP"

echo "→ verify archs"
lipo -info "$APP/Contents/MacOS/${APP_NAME}"

echo "→ zip"
(cd "$DIST" && ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${APP_NAME}-v${VERSION}-universal.zip")

ls -lh "$DIST"
echo
echo "Done. Open: open \"$APP\""
