#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"

echo "============================================================"
echo "   🚀 NAVER MAP AUTO-AGREE (v2 Reliable)"
echo "============================================================"

# 1. 화면 로딩 대기 루프
echo "[-] Waiting for Agreement Screen..."
MAX_WAIT=30
for i in $(seq 1 $MAX_WAIT); do
    # 화면 덤프 및 키워드 확인
    adb -s $DEVICE_ID shell uiautomator dump /sdcard/view.xml >/dev/null 2>&1
    if adb -s $DEVICE_ID shell "grep -q '네이버지도 약관동의' /sdcard/view.xml"; then
        echo "[✓] Agreement Screen Detected!"
        break
    fi
    
    if [ $i -eq $MAX_WAIT ]; then
        echo "[!] Timeout waiting for screen. Attempting clicks anyway..."
    else
        echo "    [...] Waiting ($i/$MAX_WAIT)..."
        sleep 1
    fi
done

# 2. 클릭 시퀀스
echo "[-] Step 1: Clicking Mandatory Checkbox..."
# (필수) 항목 체크박스 위치
adb -s $DEVICE_ID shell input tap 100 990
sleep 1

echo "[-] Step 2: Clicking Final 'Agree' Button..."
# 하단 커다란 [동의] 버튼 중앙
adb -s $DEVICE_ID shell input tap 540 1985
sleep 1

echo "============================================================"
echo " [✓] AUTO-AGREE SEQUENCE FINISHED."
echo "============================================================"
