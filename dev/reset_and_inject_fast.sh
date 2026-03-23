#!/bin/bash

# Configuration (SHORTCUT v3.4)
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} 
PKG_GPS="com.rosteam.gpsemulator"
UID_VAL="10332"

echo "============================================================"
echo "   [SHORTCUT MODE] PINNED ROUTE INJECTION"
echo "============================================================"

# 1. 경로 데이터 생성 및 '고정 마크' 강제 주입
python3 lib/utils/smart_route_gen.py $PLACE_ID 1 > /dev/null
python3 lib/utils/rebuild_xml.py > /dev/null

PREFS_FILE="lib/final_1_prefs.xml"
adb -s $DEVICE_ID push "$PREFS_FILE" /sdcard/fixed_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "cp /sdcard/fixed_prefs.xml /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"
adb -s $DEVICE_ID shell su -c "chown $UID_VAL:$UID_VAL /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml"

# 2. 앱 실행
adb -s $DEVICE_ID shell monkey -p $PKG_GPS -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 4.5

# 3. [최단 경로] 햄버거 메뉴를 열자마자 고정된 Target_Route_01 클릭
# 메뉴 버튼(79 175) -> 고정 항목(431 610)
echo "[-] Executing 2-Step Shortcut..."
adb -s $DEVICE_ID shell input tap 79 175 
sleep 0.5
adb -s $DEVICE_ID shell input tap 431 610

echo "[✓] PINNED ROUTE ACTIVATED."
