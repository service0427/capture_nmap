#!/bin/bash
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "Starting Frida trace..."
frida -D $DEVICE_ID -f $PKG_GPS -l dev/track_intent.js > dev/intent_log.txt 2>&1 &
FRIDA_PID=$!

sleep 5

echo "Starting UI Automation..."
bash lib/utils/reset_and_inject.sh 1889658893 > /dev/null

sleep 5
kill $FRIDA_PID
echo "Done"
