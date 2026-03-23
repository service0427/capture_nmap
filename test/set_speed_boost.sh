#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
TARGET_SPEED_KMH=${1:-400} # 기본값 400km/h

# km/h to m/s 변환
SPEED_MS=$(python3 -c "print($TARGET_SPEED_KMH / 3.6)")

echo "============================================================"
echo "   🚀 SPEED BOOST CONTROLLER"
echo "   Target Speed: $TARGET_SPEED_KMH km/h ($SPEED_MS m/s)"
echo "============================================================"

# 시스템 프로퍼티에 주입 (Frida가 실시간으로 가로챔)
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.speed $SPEED_MS"

echo " [✓] Speed boost applied via Frida."
echo "     Naver Map now perceives speed as $TARGET_SPEED_KMH km/h."
echo "     (To reset, run: ./dev/set_speed_boost.sh 0)"
echo "============================================================"
