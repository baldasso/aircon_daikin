#!/bin/zsh
# Archives Aircon with your Apple Developer team's signing and uploads it to App Store Connect.
#
#   TEAM_ID=ABCDE12345 scripts/upload-to-app-store.sh            archive and upload
#   TEAM_ID=ABCDE12345 scripts/upload-to-app-store.sh --no-upload archive and export a .pkg only
#
# Needs: the Apple Developer Program, your account signed in under Xcode → Settings → Accounts, and the
# app record created in App Store Connect with bundle ID dev.baldasso.aircon. Bump CFBundleVersion in
# project.yml before each upload; App Store Connect rejects a build number it has seen.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${TEAM_ID:?Set TEAM_ID to your Apple Developer team ID (developer.apple.com → Membership)}"

ARCHIVE=build.noindex/Aircon.xcarchive
EXPORT=build.noindex/export
OPTIONS=$(mktemp)
DESTINATION=upload
[[ "${1:-}" == "--no-upload" ]] && DESTINATION=export

cat > "$OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>$DESTINATION</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST

echo "→ Testing AirconKit"
(cd Packages/AirconKit && swift test --quiet)

echo "→ Archiving (universal, signed for team $TEAM_ID)"
xcodegen generate --quiet
rm -rf "$ARCHIVE" "$EXPORT"
xcodebuild archive -project Aircon.xcodeproj -scheme Aircon -configuration Release \
    -destination 'generic/platform=macOS' -archivePath "$ARCHIVE" \
    CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" DEVELOPMENT_TEAM="$TEAM_ID" \
    -allowProvisioningUpdates -quiet

echo "→ Exporting ($DESTINATION)"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
    -exportOptionsPlist "$OPTIONS" -allowProvisioningUpdates -quiet
rm -f "$OPTIONS"

if [[ $DESTINATION == upload ]]; then
    echo "✓ Uploaded. It shows up in App Store Connect → TestFlight after processing (usually under an hour)."
else
    echo "✓ Exported to $EXPORT"
fi
