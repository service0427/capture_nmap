#!/bin/bash

# Configuration (POPUP HANDLING DEV)
DEVICE_ID="RF9XC00EXGM"
PKG_GPS="com.rosteam.gpsemulator"

echo "============================================================"
echo "   [POPUP DEBUG] STABLE STARTUP SEQUENCE"
echo "============================================================"

# 1. 앱 메인 실행
echo "[-] 1. Launching GPS Emulator (Main)..."
adb -s $DEVICE_ID shell "monkey -p $PKG_GPS -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
sleep 4.5 # 팝업이 뜨는 시간 대기

# 2. 첫 실행 팝업 강제 확인 (확인 버튼 좌표: 929 1293)
echo "[-] 2. Dismissing Startup Popup..."
adb -s $DEVICE_ID shell input tap 929 1293
sleep 1.0

# 3. 북마크 화면으로 점프
echo "[-] 3. Jumping to Bookmarks..."
adb -s $DEVICE_ID shell su -c "am start -n com.rosteam.gpsemulator/.Bookmarks02" > /dev/null 2>&1
sleep 3.5

# 4. 경로 탭 및 항목 클릭 (검증용)
echo "[-] 4. Switching Tab & Selecting Route..."
adb -s $DEVICE_ID shell input tap 575 324 # 경로 탭
sleep 1.2
adb -s $DEVICE_ID shell input tap 623 472 # Target_Route_01 (최신 좌표)

echo "============================================================"
echo " [✓] DEBUG RUN COMPLETE."
echo "============================================================"
