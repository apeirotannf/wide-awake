#!/bin/sh
# Launches Wide Awake switched on and confirms macOS sees its sleep block.
cd "$(dirname "$0")"
./build.sh || exit 1
"build/Wide Awake.app/Contents/MacOS/WideAwake" -activateOnLaunch YES & pid=$!
sleep 2
pmset -g assertions | grep -q "Wide Awake is active"; found=$?
kill $pid
[ $found -eq 0 ] && echo PASS || { echo FAIL; exit 1; }
