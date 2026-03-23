#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "============================================================"
echo "   🚀 GPS EMULATOR - 999KM/H NATIVE BOOST"
echo "============================================================"

# 1. 기존 앱 종료
adb -s $DEVICE_ID shell am force-stop $PKG_GPS

# 2. Frida 실행 (GPS Emulator를 타겟으로 speed_boost.js 주입)
echo "[-] Launching GPS Emulator with 999km/h Hook..."
frida -D $DEVICE_ID -f $PKG_GPS -l dev/speed_boost.js
