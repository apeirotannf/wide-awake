#!/bin/sh
# Launches Caffeine switched on and confirms macOS sees its sleep block.
cd "$(dirname "$0")"
./build.sh || exit 1
build/Caffeine.app/Contents/MacOS/Caffeine -activateOnLaunch YES & pid=$!
sleep 2
pmset -g assertions | grep -q "Caffeine is active"; found=$?
kill $pid
[ $found -eq 0 ] && echo PASS || { echo FAIL; exit 1; }
