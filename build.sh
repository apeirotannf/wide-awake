#!/bin/sh
# Builds a universal build/Doppio.app. Needs only Xcode's command line tools.
set -e
cd "$(dirname "$0")"
app=build/Doppio.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp Info.plist "$app/Contents/"
swiftc -O -target arm64-apple-macos13 Doppio.swift -o build/Doppio-arm64
swiftc -O -target x86_64-apple-macos13 Doppio.swift -o build/Doppio-x86_64
lipo -create build/Doppio-arm64 build/Doppio-x86_64 -output "$app/Contents/MacOS/Doppio"
rm build/Doppio-arm64 build/Doppio-x86_64
codesign --force --sign - "$app"
echo "Built $app"
