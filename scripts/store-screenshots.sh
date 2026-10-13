#!/bin/zsh
# Captures the panel in its key states and composes the App Store screenshots, in English and Portuguese.
#
#   scripts/store-screenshots.sh            → docs/appstore/screenshots/<lang>/*.png
#
# Needs an unlocked screen (macOS won't capture windows while locked) and the Screen Recording permission
# for the terminal. Only the app's own panel is captured, by window id. Run it on a Retina screen to get
# 2560×1600 images; a standard screen gives 1280×800. Both sizes are accepted by the Mac App Store.
set -euo pipefail
cd "$(dirname "$0")/.."

WORK=$(mktemp -d)
OUT=docs/appstore/screenshots
APP=build.noindex/Build/Products/Debug/Aircon.app/Contents/MacOS/Aircon

swift -e 'import CoreGraphics; let d = CGSessionCopyCurrentDictionary() as? [String: Any]; exit((d?["CGSSessionScreenIsLocked"] as? Bool) == true ? 1 : 0)' \
    || { echo "The screen is locked; unlock it and run again."; exit 1; }

echo "→ Building"
xcodegen generate --quiet
xcodebuild -project Aircon.xcodeproj -scheme Aircon -configuration Debug -derivedDataPath build.noindex build -quiet
swiftc -O -o "$WORK/winshot" scripts/window-capture.swift

# Pretend units under real-looking names, so the panel shows no demo badge.
units() {
    cat > "$WORK/units-$1.json" <<EOF
[{"name": "$2", "host": "1.demo", "key": "", "canHeat": true},
 {"name": "$3", "host": "2.demo", "key": ""},
 {"name": "$4", "host": "3.demo", "key": ""}]
EOF
}
units en "Living room" "Bedroom" "Guest room"
units pt-BR "Sala" "Quarto" "Hóspedes"
echo '[]' > "$WORK/none.json"

capture() {  # capture <out> <lang> <devices file> [VAR=value…]
    local out=$1 lang=$2 devices=$3; shift 3
    pkill -x Aircon 2>/dev/null || true
    sleep 0.8
    env AIRCON_DEVICES_FILE="$devices" AIRCON_SHOW=controls "$@" "$APP" -AppleLanguages "($lang)" >/dev/null 2>&1 &
    sleep 5
    "$WORK/winshot" Aircon "$out"
}

compose() {  # compose <panel> <out> <headline> <subhead>
    local width=1280
    (( $(sips -g pixelWidth "$1" | awk '/pixelWidth/{print $2}') > 500 )) && width=2560
    swift scripts/compose-screenshot.swift "$1" "$2" "$3" "$4" $width
}

for lang in en pt-BR; do
    mkdir -p "$OUT/$lang"
    if [[ $lang == en ]]; then
        rooms=("Living room" "Guest room" "Bedroom")
        copy=(
            "Your air conditioners, one click away|Every Daikin Smart AC unit in your home, right in the Mac menu bar."
            "Drag to set the temperature|Mode, fan speed and swing are all within reach."
            "Every room at a glance|A lit dot means that room's unit is running."
            "Stays on your Wi-Fi|No account and no cloud. Set it up with the key from the Daikin Smart AC app."
        )
    else
        rooms=("Sala" "Hóspedes" "Quarto")
        copy=(
            "Seu ar-condicionado a um clique|Todos os aparelhos Daikin Smart AC da casa, direto na barra de menus do Mac."
            "Arraste para ajustar a temperatura|Modo, ventilação e oscilação sempre à mão."
            "Todos os cômodos de relance|Ponto aceso: o aparelho daquele cômodo está ligado."
            "Fica na sua rede Wi-Fi|Sem conta e sem nuvem. Configure com a chave do app Daikin Smart AC."
        )
    fi
    capture "$WORK/1-$lang.png" $lang "$WORK/units-$lang.json" AIRCON_ROOM="${rooms[1]}"
    capture "$WORK/2-$lang.png" $lang "$WORK/units-$lang.json" AIRCON_ROOM="${rooms[2]}"
    capture "$WORK/3-$lang.png" $lang "$WORK/units-$lang.json" AIRCON_ROOM="${rooms[3]}"
    capture "$WORK/4-$lang.png" $lang "$WORK/none.json"
    for i in 1 2 3 4; do
        compose "$WORK/$i-$lang.png" "$OUT/$lang/$i.png" "${copy[$i]%%|*}" "${copy[$i]#*|}"
    done
done
pkill -x Aircon 2>/dev/null || true
echo "✓ Screenshots in $OUT"
