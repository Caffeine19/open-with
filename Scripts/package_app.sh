#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

APP_NAME="OpenWith"
BUNDLE_ID="com.caffeinecat.openwith"
VERSION="1.0.0"
BUILD_NUMBER="1"

echo "==> Building $APP_NAME ($CONF)..."
swift build -c "$CONF"

echo "==> Creating app bundle..."
APP="$ROOT/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Copy binary
cp "$ROOT/.build/$CONF/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"

# Convert PNG to ICNS if needed
ICON_PNG="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
ICON_ICNS="$ROOT/Resources/Icon.icns"

if [[ -f "$ICON_PNG" ]]; then
  echo "==> Converting PNG to ICNS..."
  ICONSET="$ROOT/Resources/AppIcon.iconset"
  mkdir -p "$ICONSET"
  
  # Generate all required icon sizes
  sips -z 16 16     "$ICON_PNG" --out "$ICONSET/icon_16x16.png" 2>/dev/null
  sips -z 32 32     "$ICON_PNG" --out "$ICONSET/icon_16x16@2x.png" 2>/dev/null
  sips -z 32 32     "$ICON_PNG" --out "$ICONSET/icon_32x32.png" 2>/dev/null
  sips -z 64 64     "$ICON_PNG" --out "$ICONSET/icon_32x32@2x.png" 2>/dev/null
  sips -z 128 128   "$ICON_PNG" --out "$ICONSET/icon_128x128.png" 2>/dev/null
  sips -z 256 256   "$ICON_PNG" --out "$ICONSET/icon_128x128@2x.png" 2>/dev/null
  sips -z 256 256   "$ICON_PNG" --out "$ICONSET/icon_256x256.png" 2>/dev/null
  sips -z 512 512   "$ICON_PNG" --out "$ICONSET/icon_256x256@2x.png" 2>/dev/null
  sips -z 512 512   "$ICON_PNG" --out "$ICONSET/icon_512x512.png" 2>/dev/null
  sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET/icon_512x512@2x.png" 2>/dev/null
  
  iconutil -c icns "$ICONSET" -o "$ICON_ICNS"
  rm -rf "$ICONSET"
fi

if [[ -f "$ICON_ICNS" ]]; then
  cp "$ICON_ICNS" "$APP/Contents/Resources/AppIcon.icns"
fi

# Generate Info.plist
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>OpenWith</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 CaffeineCat. All rights reserved.</string>
</dict>
</plist>
PLIST

# Strip extended attributes
xattr -cr "$APP" 2>/dev/null || true

# Ad-hoc code sign
echo "==> Signing app bundle..."
codesign --force --deep --sign - "$APP"

echo "==> Done! Created $APP"
echo "    Run with: open $APP"
