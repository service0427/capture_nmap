#!/bin/bash

# Configuration (PINNED SHORTCUT TEST)
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "============================================================"
echo "   [UI TEST] DRAWER PINNED ROUTE SHORTCUT"
echo "============================================================"

# 1. 앱 메인 화면 실행 (이미 켜져 있으면 초기화)
echo "[-] 1. Launching GPS Emulator..."
adb -s $DEVICE_ID shell monkey -p $PKG_GPS -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 4.5 # 지도 로딩 대기

# 2. 좌상단 햄버거(메뉴) 버튼 클릭
echo "[-] 2. Opening Drawer Menu..."
adb -s $DEVICE_ID shell input tap 79 175
sleep 1.5

# 3. 고정된 'Target_Route_01' 클릭 (분석된 좌표: 431 610)
echo "[-] 3. Clicking Pinned Route: Target_Route_01..."
adb -s $DEVICE_ID shell input tap 431 610
sleep 1.0

echo "============================================================"
echo " [✓] PINNED CLICK COMPLETE."
echo " 이 시점에서 경로가 지도에 표시되었다면 '북마크' 단계를 뺀 것입니다!"
echo "============================================================"
