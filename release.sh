#!/bin/sh
# Build Plume.app and package it for a GitHub release. Usage: ./release.sh
set -eu
cd "$(dirname "$0")"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
zip="Plume-$version.zip"
./build.sh
lipo -archs Plume.app/Contents/MacOS/Plume
rm -f "$zip"
ditto -c -k --keepParent Plume.app "$zip"
shasum -a 256 "$zip"
echo "Next: git tag v$version && git push origin v$version && gh release create v$version $zip"
