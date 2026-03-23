#!/bin/bash
# High-Fidelity Route Switcher (v1.0)

LIB_FILE="route_library/$1.json"

if [ ! -f "$LIB_FILE" ]; then
    echo "[!] Error: File not found in library: $1"
    echo "[*] Available list (first 10):"
    ls -1 route_library/*.json | head -n 10 | sed 's/route_library\///g' | sed 's/.json//g'
    exit 1
fi

# 1. 기기에 데이터 푸시
adb -s RF9XC00EXGM push "$LIB_FILE" /data/local/tmp/target_route.json

# 2. 하이재킹 엔진에 신호 (파일 교체만으로도 엔진이 다음 루프에서 반영)
echo "[✓] Route switched to: $1"
echo "[*] Next loop in GPS Joystick will use this route."
