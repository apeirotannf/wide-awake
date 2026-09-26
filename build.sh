#!/bin/sh
# Builds a universal build/Caffeine.app. Needs only Xcode's command line tools.
set -e
cd "$(dirname "$0")"
app=build/Caffeine.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp Info.plist "$app/Contents/"
swiftc -O -target arm64-apple-macos13 Caffeine.swift -o build/Caffeine-arm64
swiftc -O -target x86_64-apple-macos13 Caffeine.swift -o build/Caffeine-x86_64
lipo -create build/Caffeine-arm64 build/Caffeine-x86_64 -output "$app/Contents/MacOS/Caffeine"
rm build/Caffeine-arm64 build/Caffeine-x86_64
codesign --force --sign - "$app"
echo "Built $app"
