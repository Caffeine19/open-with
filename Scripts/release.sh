#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

"$SCRIPT_DIR/package_app.sh"

APP_PATH="$PROJECT_ROOT/OpenWith.app"

echo ""
echo "Release complete!"
echo "App: \"$APP_PATH\""
