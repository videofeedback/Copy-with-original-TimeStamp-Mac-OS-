#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Copy With Creation Date"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/copy-with-creation-date-dmg.XXXXXX")"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

cleanup() {
    if [ -d "$DMG_ROOT" ]; then
        chmod -R u+w "$DMG_ROOT" 2>/dev/null || true
        rm -rf "$DMG_ROOT" 2>/dev/null || true
    fi
}
trap cleanup EXIT

cd "$ROOT_DIR"
export COPYFILE_DISABLE=1
"$ROOT_DIR/Scripts/build-app.sh"

rm -f "$DMG_PATH"
mkdir -p "$DMG_ROOT"
ditto --norsrc "$APP_DIR" "$DMG_ROOT/$APP_NAME.app"
find "$DMG_ROOT" -name '._*' -delete
xattr -cr "$DMG_ROOT"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Built $DMG_PATH"
