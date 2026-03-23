#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
TARGET_NAME="달빛잔기지떡"
DEST_LAT="37.6428285"
DEST_LNG="126.6721551"

echo "============================================================"
echo "   🚀 NAVER MAP SMART ROUTE JUMP (Deep Link)"
echo "   Target: $TARGET_NAME"
echo "============================================================"

# 1. 딥링크를 이용한 길찾기 즉시 실행 (자동차 경로 기준)
echo "[-] Sending Directions Intent (Direct to Route Preview)..."
# URL 인코딩된 이름 사용 (달빛잔기지떡)
ENCODED_NAME=$(python3 -c "import urllib.parse; print(pythonurllib.parse.quote('$TARGET_NAME'))" 2>/dev/null || echo "%EB%8B%AC%EB%B9%9B%EC%9E%94%EA%B8%B0%EC%A7%80%EB%96%A1")

adb -s $DEVICE_ID shell am start -a android.intent.action.VIEW \
    -d "nmap://route/car?dlat=$DEST_LAT&dlng=$DEST_LNG&dname=$ENCODED_NAME" >/dev/null 2>&1

# 2. 경로 계산 및 미리보기 화면 로딩 대기
echo "[-] Waiting for route preview to load..."
sleep 4

echo "============================================================"
echo " [✓] ROUTE PREVIEW LOADED SUCCESSFULLY."
echo "     Next: Auto-click 'Start Navigation' button."
echo "============================================================"
