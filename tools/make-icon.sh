#!/bin/sh
# Turns tools/icon-1024.png into Resources/Plume.icns
set -eu
cd "$(dirname "$0")/.."
set=$(mktemp -d)/Plume.iconset
mkdir "$set"
for s in 16 32 128 256; do
    sips -z $s $s tools/icon-1024.png --out "$set/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) tools/icon-1024.png --out "$set/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$set" -o Resources/Plume.icns
