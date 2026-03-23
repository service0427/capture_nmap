#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
INTERVAL=10

echo "============================================================"
echo "   🚀 RANDOM SPEED CYCLER (10-100 km/h)"
echo "   Interval: $INTERVAL seconds"
echo "   Target: $DEVICE_ID"
echo "============================================================"

# 종료 시 초기화
trap "echo -e '\n[-] Stopping... Clearing speed.'; adb -s $DEVICE_ID shell su -c \"setprop debug.nmap.speed ''\"; exit" INT TERM

while true; do
    # 10에서 100 사이의 랜덤 정수 생성
    TARGET_KMH=$(( ( RANDOM % 91 )  + 10 ))
    
    # km/h를 m/s로 변환 (Frida 주입용)
    SPEED_MS=$(python3 -c "print($TARGET_KMH / 3.6)")
    
    echo "[*] [$(date +%H:%M:%S)] Changing Speed to: $TARGET_KMH km/h ($SPEED_MS m/s)"
    
    # 시스템 프로퍼티에 주입
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.speed $SPEED_MS"
    
    sleep $INTERVAL
done
