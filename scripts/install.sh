#!/bin/zsh
# Builds Aircon in Release, runs the tests, and installs it to /Applications.
#
#   scripts/install.sh                      build, test, install, launch
#   scripts/install.sh --import units.json  also add the units in that file to the keychain
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build.noindex/Build/Products/Release/Aircon.app"
DEST="/Applications/Aircon.app"

echo "→ Testing AirconKit"
(cd Packages/AirconKit && swift test --quiet)

echo "→ Building Release"
xcodegen generate --quiet
xcodebuild -project Aircon.xcodeproj -scheme Aircon -configuration Release -derivedDataPath build.noindex build -quiet
codesign --verify --strict "$APP"

echo "→ Installing to $DEST"
pkill -x Aircon 2>/dev/null || true
rm -rf "$DEST"
cp -R "$APP" "$DEST"

if [[ "${1:-}" == "--import" && -n "${2:-}" ]]; then
    echo "→ Importing units into the keychain"
    "$DEST/Contents/MacOS/Aircon" --import "$2"
fi

open "$DEST"
echo "✓ Aircon is in the menu bar"
