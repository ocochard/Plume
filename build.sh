#!/bin/sh
# Build Plume.app (ad-hoc signed). Usage: ./build.sh
set -eu
cd "$(dirname "$0")"
swift build -c release
app=Plume.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/Plume "$app/Contents/MacOS/"
cp Info.plist "$app/Contents/"
cp Resources/* "$app/Contents/Resources/"
strip "$app/Contents/MacOS/Plume"
codesign --force --sign - "$app"
du -sh "$app"
