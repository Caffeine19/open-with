#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

ICNS_PATH="${1:?Usage: $0 <path-to-icon.icns>}"
ICONSET_TMP="$(mktemp -d)/AppIcon.iconset"
DEST_DIR="$PROJECT_ROOT/Resources/Assets.xcassets/AppIcon.appiconset"

iconutil -c iconset "$ICNS_PATH" -o "$ICONSET_TMP"

# Contents.json uses a single AppIcon.png for all sizes — write the largest
# available PNG (1024x1024) as the source image.
SRC="$ICONSET_TMP/icon_512x512@2x.png"
[[ -f "$SRC" ]] || SRC="$ICONSET_TMP/icon_512x512.png"
cp "$SRC" "$DEST_DIR/AppIcon.png"

rm -rf "$(dirname "$ICONSET_TMP")"
echo "==> Wrote $DEST_DIR/AppIcon.png"
