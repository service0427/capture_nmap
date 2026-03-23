#!/bin/bash

# Configuration (STABLE SELECT MODE)
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "============================================================"
echo "   [STABLE UI TEST] ROUTE SELECTION ONLY"
echo "============================================================"

# 1. 북마크 화면 다이렉트 호출
echo "[-] 1. Launching Bookmarks Screen..."
adb -s $DEVICE_ID shell su -c "am start -n com.rosteam.gpsemulator/.Bookmarks02" > /dev/null 2>&1
sleep 3.5 # 화면 로딩 및 렌더링을 위한 충분한 대기

# 2. "경로(Route)" 탭 강제 선택
echo "[-] 2. Switching to 'Route' Tab..."
adb -s $DEVICE_ID shell input tap 575 324
sleep 1.5 # 탭 전환 애니메이션 대기

# 3. Target_Route_01 항목 클릭
echo "[-] 3. Selecting 'Target_Route_01'..."
adb -s $DEVICE_ID shell input tap 623 626 
sleep 1.0 # 클릭 인식 대기

echo "============================================================"
echo " [✓] STABLE SELECT COMPLETE."
echo " 이 시점에서 '메인 지도 화면'으로 돌아와 있다면 성공입니다!"
echo "============================================================"
