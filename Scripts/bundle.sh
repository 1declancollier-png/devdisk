#!/bin/bash
# Builds devdisk.app from a clean checkout using only Command Line Tools.
# Deliberately not xcodebuild: requiring a full Xcode install to produce the app would make
# the build unreproducible for anyone auditing the delete-path claims.
set -euo pipefail

cd "$(dirname "$0")/.."
CONFIG="${1:-release}"
APP=".build/devdisk.app"
BUNDLE_ID="com.devdisk.app"
VERSION="$(git describe --tags --always 2>/dev/null || echo 0.1.0)"

swift build -c "$CONFIG" --product DevDiskApp

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/DevDiskApp" "$APP/Contents/MacOS/devdisk"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>devdisk</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>devdisk</string>
  <key>CFBundleDisplayName</key><string>devdisk</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <!-- Conventional for app bundles (Xcode emits it); tested as not strictly required here. -->
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Needs no Full Disk Access.</string>
</dict></plist>
PLIST

# Ad-hoc for local runs. Release builds re-sign with the Developer ID and notarize; see SPEC.md §5.
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --verbose=2 "$APP" 2>&1 | sed 's/^/  /'
echo "built $APP ($VERSION)"
