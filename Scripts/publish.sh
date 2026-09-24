#!/bin/bash
# Publish Release — build, package, and create a GitHub release in one command
set -e

if [ -z "$1" ]; then
    echo "Usage: ./Scripts/publish.sh <version>   (e.g. ./Scripts/publish.sh 1.0.0)"
    exit 1
fi

VERSION="$1"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

gh auth status >/dev/null 2>&1 || {
    echo "gh is not logged in. Run 'gh auth login' first."
    exit 1
}

# 1. Build the release app bundle
"$SCRIPT_DIR/release.sh"

# 2. Package the app into a zip (ditto preserves signing & permissions)
APP_PATH="$PROJECT_ROOT/OpenWith.app"
ZIP_PATH="dist/OpenWith-$VERSION.zip"
mkdir -p dist
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# 3. Create the GitHub release and upload the zip (tag = version, auto notes)
gh release create "$VERSION" "$ZIP_PATH" --generate-notes

echo ""
echo "Published! https://github.com/Caffeine19/open-with/releases/tag/$VERSION"
