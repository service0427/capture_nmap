#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"

echo "============================================================"
echo "   🚀 NAVER MAP CAPTURE - 999KM/H BOOST MODE"
echo "============================================================"

# 1. 기존 앱 종료
adb -s $DEVICE_ID shell am force-stop $PKG_NAME

# 2. Frida 실행 (Bypass + Boost 동시 주입)
echo "[-] Launching Naver Map with 999km/h Hook..."
frida -D $DEVICE_ID -f $PKG_NAME -l lib/bypass.js -l dev/speed_boost.js
