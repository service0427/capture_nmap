#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} 
PKG_NAME="com.rosteam.gpsemulator"
UID_VAL="10332"

# 폴더 위치 고정 (스크립트 위치 기준)
DEV_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$DEV_DIR/.." && pwd)
cd "$ROOT_DIR" # 루트에서 실행하여 경로 일관성 유지

echo "============================================================"
echo "   [DEV] STABLE SINGLE ROUTE INJECTOR"
echo "============================================================"

# 1. 앱 먼저 종료 (데이터 오염 방지)
echo "[-] Step 1: Stopping app..."
adb -s $DEVICE_ID shell "am force-stop $PKG_NAME"

# 2. 기존 로컬/기기 잔재 삭제
echo "[-] Step 2: Cleaning up existing routes..."
rm -f route_library/*.json
adb -s $DEVICE_ID shell "su -c 'rm -f /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"

# 3. 1개의 경로만 생성
echo "[-] Step 3: Generating 1 new random route..."
python3 smart_route_gen.py $PLACE_ID 1

# 4. XML 빌드
echo "[-] Step 4: Rebuilding SharedPreference..."
python3 rebuild_xml.py

# 5. 기기 주입
echo "[-] Step 5: Injecting to device..."
PREFS_FILE="lib/final_1_prefs.xml"
adb -s $DEVICE_ID push "$PREFS_FILE" /sdcard/fixed_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell "su -c 'cp /sdcard/fixed_prefs.xml /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"
adb -s $DEVICE_ID shell "su -c 'chmod 660 /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"
adb -s $DEVICE_ID shell "su -c 'chown $UID_VAL:$UID_VAL /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"

# 6. 앱 다시 켜기
echo "[-] Step 6: Restarting app for inspection..."
adb -s $DEVICE_ID shell "monkey -p $PKG_NAME -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1

echo "============================================================"
echo " [✓] DONE: Check the app. Should see ONLY 'test0001' & 'Target_Route_01'."
echo "============================================================"
