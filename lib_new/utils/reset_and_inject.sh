#!/bin/bash

# Configuration (STABLE ORIGINAL v1.2)
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} 
PKG_GPS="com.rosteam.gpsemulator"
PKG_MAP="com.nhn.android.nmap"
UID_VAL="10332"

# 경로 설정
UTILS_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$UTILS_DIR/../.." && pwd)
cd "$ROOT_DIR"

echo "============================================================"
echo "   [STABLE] ORIGINAL UI AUTOMATION SEQUENCE"
echo "============================================================"

# 1. 앱 강제 종료 및 데이터 청소
echo "[-] Stopping apps & Cleaning data..."
adb -s $DEVICE_ID shell "am force-stop $PKG_GPS"
adb -s $DEVICE_ID shell "am force-stop $PKG_MAP"
# [FIX] 외부에서 생성된 파일을 지우지 않도록 수정
# rm -f route_library/*.json
adb -s $DEVICE_ID shell "su -c 'rm -f /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml'"

# 2. XML 빌드 (경로는 이미 생성되어 있음)
echo "[-] Rebuilding high-fidelity XML..."
python3 lib/utils/rebuild_xml.py > /dev/null

# 3. 설정 주입
echo "[-] Injecting configuration..."
PREFS_FILE="lib/final_1_prefs.xml"
adb -s $DEVICE_ID push "$PREFS_FILE" /sdcard/fixed_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "cp /sdcard/fixed_prefs.xml /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"
adb -s $DEVICE_ID shell su -c "chown $UID_VAL:$UID_VAL /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"

# 4. 앱 정식 실행 (Monkey)
echo "[-] Launching GPS Emulator..."
adb -s $DEVICE_ID shell "monkey -p $PKG_GPS -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
sleep 5.0 # 초기 팝업 대기 시간 넉넉히 확보

# 5. [순정 시퀀스] 팝업 확인 -> 메뉴 -> 북마크 -> 경로탭 -> 선택
echo "[-] Executing Full UI Sequence..."

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

echo "    > Selecting Target_Route_01 (Stable Y:472)..."
adb -s $DEVICE_ID shell input tap 623 472 
sleep 2.5

# 6. 주행 시작 (Play + Speed + Start)
echo "    > Clicking Play button..."
adb -s $DEVICE_ID shell input tap 539 2089
sleep 1.5

SPEED_X=$((200 + RANDOM % 31))
echo "    > Adjusting speed (SeekBar)..."
adb -s $DEVICE_ID shell input tap $SPEED_X 1090
sleep 1

echo "    > Confirming Route Start..."
adb -s $DEVICE_ID shell input tap 929 1585

echo "============================================================"
echo " [✓] STABLE AUTO-START COMPLETE!"
echo "============================================================"
