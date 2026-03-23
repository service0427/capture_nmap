#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"

echo "============================================================"
echo "   🚀 NAVER MAP AUTO-SEARCH (Detection Mode)"
echo "============================================================"

# 1. 메인 화면 로딩 대기 루프 (검색창 기준)
echo "[-] Waiting for Main Map Screen (Search Bar)..."
MAX_WAIT=60  # 네트워크 로딩 고려하여 최대 60초 대기
for i in $(seq 1 $MAX_WAIT); do
    # 화면 덤프 및 검색창 ID 확인
    adb -s $DEVICE_ID shell uiautomator dump /sdcard/main_view.xml >/dev/null 2>&1
    if adb -s $DEVICE_ID shell "grep -q 'com.nhn.android.nmap:id/searchField' /sdcard/main_view.xml"; then
        echo "[✓] Main Screen Detected! (Search Bar Found)"
        break
    fi
    
    if [ $i -eq $MAX_WAIT ]; then
        echo "[!] Timeout waiting for Main Screen. Attempting click anyway..."
        break
    fi
    echo "    [...] Waiting for Map Loading ($i/$MAX_WAIT)..."
    sleep 1
done

# 2. 검색창 클릭
echo "[-] Clicking Search Bar..."
# 검색 필드 중앙 좌표 [540, 190]
adb -s $DEVICE_ID shell input tap 540 190
sleep 1

echo "============================================================"
echo " [✓] AUTO-SEARCH SEQUENCE FINISHED."
echo "============================================================"
