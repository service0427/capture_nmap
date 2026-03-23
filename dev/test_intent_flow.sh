#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "[-] Injecting Target Route to Emulator..."
bash lib/utils/reset_and_inject.sh 1889658893 &

echo "[-] Starting Frida Intent Tracker (Wait for UI automation to hit Play)..."
# wait for the app to launch before hooking
sleep 5
frida -D $DEVICE_ID -f $PKG_GPS -l dev/track_intent.js
