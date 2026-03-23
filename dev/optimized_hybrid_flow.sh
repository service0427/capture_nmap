#!/bin/bash

# Configuration (HYBRID OPTIMIZED v1.3 - Direct Jump)
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} 
PKG_GPS="com.rosteam.gpsemulator"
UID_VAL="10332"

echo "============================================================"
echo "   [HYBRID] DIRECT ACTIVITY JUMP MODE"
echo "============================================================"

# 1. 경로 데이터 및 설정 주입 (백그라운드)
python3 lib/utils/smart_route_gen.py $PLACE_ID 1 > /dev/null
python3 lib/utils/rebuild_xml.py > /dev/null
PREFS_FILE="lib/final_1_prefs.xml"
adb -s $DEVICE_ID push "$PREFS_FILE" /sdcard/fixed_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "cp /sdcard/fixed_prefs.xml /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"
adb -s $DEVICE_ID shell su -c "chown $UID_VAL:$UID_VAL /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"

# 2. [Step 1] 북마크 화면으로 즉시 다이렉트 점프 (Monkey 생략)
echo "[-] 1. Jumping to Bookmarks Screen..."
adb -s $DEVICE_ID shell su -c "am start -n com.rosteam.gpsemulator/.Bookmarks02" > /dev/null 2>&1
sleep 4.0 # 화면 로딩 및 리스트 초기화 시간 대기

# 3. [Step 2] "경로(Route)" 탭 강제 클릭 (Tab Index 1)
echo "[-] 2. Activating 'Route' Tab..."
adb -s $DEVICE_ID shell input tap 575 324
sleep 2.0 # 리스트 갱신 시간 넉넉히 확보

# 4. [Step 3] 주입된 경로(Target_Route_01) 클릭
# 덤프된 Bounds [194,438][1052,506] 의 중앙값인 623 472 사용
echo "[-] 3. Selecting Target_Route_01 (X:623 Y:472)..."
adb -s $DEVICE_ID shell input tap 423 402 
sleep 2.5

# 5. [Step 4] 최종 주행 시작 (Play)
echo "[-] 4. Starting Simulation..."
# 메인 화면으로 돌아왔을 때의 Play 버튼 위치
adb -s $DEVICE_ID shell input tap 539 2089 # Play
sleep 1.5
SPEED_X=$((190 + RANDOM % 31))
adb -s $DEVICE_ID shell input tap $SPEED_X 1090 # 속도 조절
sleep 1.0
adb -s $DEVICE_ID shell input tap 929 1585 # 시작 확인

echo "============================================================"
echo " [✓] HYBRID DIRECT JUMP COMPLETE!"
echo "============================================================"
