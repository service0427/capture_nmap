#!/bin/bash

# Configuration (DEBUG STOP MODE)
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "============================================================"
echo "   [DEBUG] STOP AT ROUTE SELECTION"
echo "============================================================"

# 1. 북마크 화면 다이렉트 점프
echo "[-] 1. Launching Bookmarks Screen..."
adb -s $DEVICE_ID shell su -c "am start -n com.rosteam.gpsemulator/.Bookmarks02" > /dev/null 2>&1
sleep 4.0 # 화면 로딩 및 리스트 렌더링 완전 대기

# 2. "경로" 탭 클릭 생략 (이미 경로 탭일 확률이 높으므로)
# 만약 필요하다면 아래 줄 주석을 해제하세요.
# adb -s $DEVICE_ID shell input tap 575 324
# sleep 1.0

# 3. Target_Route_01 클릭 (정밀 좌표: 623 472)
echo "[-] 2. Clicking Target_Route_01 at 623 472..."
adb -s $DEVICE_ID shell input tap 623 472 

echo "============================================================"
echo " [!] STOPPED. 메인 화면으로 돌아왓는지, 아니면 여전히 북마크인지 확인하세요."
echo "============================================================"
