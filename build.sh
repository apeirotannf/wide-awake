#!/bin/sh
# Builds a universal (Apple silicon + Intel) build/Doppio.app for macOS 11+. Needs Xcode 26+.
set -e
cd "$(dirname "$0")"
app=build/Doppio.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Info.plist "$app/Contents/"
# Liquid Glass icon for macOS 26+, plus AppIcon.icns for older systems.
xcrun actool "$PWD/AppIcon.icon" --compile "$PWD/$app/Contents/Resources" --platform macosx --target-device mac \
  --minimum-deployment-target 11.0 --app-icon AppIcon --output-partial-info-plist "$PWD/build/icon.plist" >/dev/null
# Swift 5 mode skips Swift 6 runtime checks, which need a library macOS 11 lacks.
swiftc -O -swift-version 5 -parse-as-library -target arm64-apple-macos11 Doppio.swift -o build/Doppio-arm64
swiftc -O -swift-version 5 -parse-as-library -target x86_64-apple-macos11 Doppio.swift -o build/Doppio-x86_64
lipo -create build/Doppio-arm64 build/Doppio-x86_64 -output "$app/Contents/MacOS/Doppio"
rm build/Doppio-arm64 build/Doppio-x86_64
codesign --force --sign - "$app"
echo "Built $app"
