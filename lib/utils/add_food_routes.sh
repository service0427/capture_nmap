#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} # 기본값: 달빛잔기지떡
PKG_NAME="com.rosteam.gpsemulator"
UID_VAL="10332"

echo "============================================================"
echo "   STABLE ROUTE INJECTOR (Single High-Quality Route)"
echo "   Target Place ID: $PLACE_ID"
echo "============================================================"

# 1. 경로 생성 (1개만 생성하도록 인자 전달)
echo "[-] Step 1: Generating high-fidelity route..."
python3 smart_route_gen.py $PLACE_ID 1

# 2. XML 빌드 (최신 1개만 포함)
echo "[-] Step 2: Rebuilding SharedPreference XML..."
python3 rebuild_xml.py

# 3. 기기 전송 및 권한 설정
echo "[-] Step 3: Injecting to device ($DEVICE_ID)..."
adb -s $DEVICE_ID push lib/final_1_prefs.xml /sdcard/final_1_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell "su -c 'cp /sdcard/final_1_prefs.xml /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"
adb -s $DEVICE_ID shell "su -c 'chmod 660 /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"
adb -s $DEVICE_ID shell "su -c 'chown $UID_VAL:$UID_VAL /data/data/$PKG_NAME/shared_prefs/${PKG_NAME}_preferences.xml'"

# 4. 앱 재시작
echo "[-] Step 4: Restarting GPS Emulator..."
adb -s $DEVICE_ID shell "am force-stop $PKG_NAME"

echo "============================================================"
echo " [✓] SUCCESS: Primary route injected and stabilized!"
echo "============================================================"
