#!/bin/bash

# Configuration (STEP-BY-STEP TEST)
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "============================================================"
echo "   [UI DEBUG] STEP 1: FORCE 'ROUTE' TAB"
echo "============================================================"

# 1. 북마크 화면 다이렉트 실행
echo "[-] Launching Bookmarks..."
adb -s $DEVICE_ID shell su -c "am start -n com.rosteam.gpsemulator/.Bookmarks02" > /dev/null 2>&1
sleep 3

# 2. "경로(Route)" 탭 강제 클릭 (위치 탭에 있을 경우를 대비)
# 좌표 [575, 324] 는 상단 탭 중 '경로' 부분입니다.
echo "[-] Clicking 'Route' Tab..."
adb -s $DEVICE_ID shell input tap 575 324
sleep 1.5

# 3. 현재 화면 상태 덤프 (검증용)
echo "[-] Current screen state captured to dev/debug_view.xml"
adb -s $DEVICE_ID shell uiautomator dump /sdcard/debug_view.xml > /dev/null
adb -s $DEVICE_ID pull /sdcard/debug_view.xml dev/debug_view.xml > /dev/null

echo "============================================================"
echo " [✓] STEP 1 COMPLETE: Check if 'Route' tab is now active."
echo "============================================================"
