#!/bin/sh
# Launches Doppio switched on and confirms macOS sees its sleep block.
cd "$(dirname "$0")"
./build.sh || exit 1
build/Doppio.app/Contents/MacOS/Doppio -activateOnLaunch YES & pid=$!
sleep 2
pmset -g assertions | grep -q "Doppio is active"; found=$?
kill $pid
[ $found -eq 0 ] && echo PASS || { echo FAIL; exit 1; }
