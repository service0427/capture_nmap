#!/bin/bash

# Configuration (ORIGINAL FULL SEQUENCE REPLICA)
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} 
PKG_GPS="com.rosteam.gpsemulator"
UID_VAL="10332"

# 경로 설정
ROOT_DIR=$(pwd)

echo "============================================================"
echo "   [RESTORE] ORIGINAL FULL UI AUTOMATION"
echo "============================================================"

# 1. 경로 데이터 생성 및 주입 (기본 데이터 처리)
echo "[-] 1. Preparing Route & XML..."
python3 lib/utils/smart_route_gen.py $PLACE_ID 1 > /dev/null
python3 lib/utils/rebuild_xml.py > /dev/null

PREFS_FILE="lib/final_1_prefs.xml"
adb -s $DEVICE_ID push "$PREFS_FILE" /sdcard/fixed_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "cp /sdcard/fixed_prefs.xml /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"
adb -s $DEVICE_ID shell su -c "chown $UID_VAL:$UID_VAL /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"

# 2. 앱 메인 실행
echo "[-] 2. Launching GPS Emulator..."
adb -s $DEVICE_ID shell "monkey -p $PKG_GPS -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
sleep 4.5 # 앱 초기 로딩 및 팝업 대기

# 3. [원본 시퀀스] 팝업 확인 -> 메뉴 -> 북마크 -> 경로탭 -> 선택
echo "[-] 3. Executing Full UI Sequence..."

echo "    > Clicking popup OK..."
adb -s $DEVICE_ID shell input tap 929 1293
sleep 1.5

echo "    > Opening drawer menu..."
adb -s $DEVICE_ID shell input tap 79 175
sleep 1.5

echo "    > Clicking Bookmarks..."
adb -s $DEVICE_ID shell input tap 428 616
sleep 1.5

echo "    > Switching to Route tab..."
adb -s $DEVICE_ID shell input tap 575 324
sleep 1.5

echo "    > Selecting Target_Route_01 (using current stable Y:472)..."
adb -s $DEVICE_ID shell input tap 623 472 
sleep 2.5

# 4. 주행 시작 (Play + Speed + Start)
echo "    > Clicking Play button..."
adb -s $DEVICE_ID shell input tap 539 2089
sleep 1.5

SPEED_X=$((190 + RANDOM % 31))
echo "    > Adjusting speed (SeekBar)..."
adb -s $DEVICE_ID shell input tap $SPEED_X 1090
sleep 1

echo "    > Confirming Route Start..."
adb -s $DEVICE_ID shell input tap 929 1585

echo "============================================================"
echo " [✓] ORIGINAL FLOW REPLICATION COMPLETE."
echo "============================================================"
