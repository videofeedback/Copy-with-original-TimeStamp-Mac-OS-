#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Copy With Creation Date"
PRODUCT_NAME="CopyWithCreationDate"
VERSION="1.0"
IDENTIFIER="com.local.copywithcreationdate"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
PAYLOAD_ROOT="$ROOT_DIR/.build/installer-payload"
COMPONENT_PKG="$ROOT_DIR/.build/$PRODUCT_NAME-component.pkg"
INSTALLER_PKG="$DIST_DIR/$APP_NAME Installer.pkg"

cd "$ROOT_DIR"
export COPYFILE_DISABLE=1
"$ROOT_DIR/Scripts/build-app.sh"

rm -rf "$PAYLOAD_ROOT" "$COMPONENT_PKG" "$INSTALLER_PKG"
mkdir -p "$PAYLOAD_ROOT/Applications"
ditto --norsrc "$APP_DIR" "$PAYLOAD_ROOT/Applications/$APP_NAME.app"
find "$PAYLOAD_ROOT" -name '._*' -delete
xattr -cr "$PAYLOAD_ROOT"

pkgbuild \
    --root "$PAYLOAD_ROOT" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    --filter '.*/\._.*' \
    "$COMPONENT_PKG"

productbuild \
    --package "$COMPONENT_PKG" \
    "$INSTALLER_PKG"

echo "Built $INSTALLER_PKG"
