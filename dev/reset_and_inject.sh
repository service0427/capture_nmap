#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PLACE_ID=${1:-"1889658893"} # 기본값: 달빛잔기지떡
PKG_GPS="com.rosteam.gpsemulator"
PKG_MAP="com.nhn.android.nmap"
UID_VAL="10332"

# 경로 절대 기준 설정
DEV_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$DEV_DIR/.." && pwd)
cd "$ROOT_DIR"

echo "============================================================"
echo "   [CYCLE STEP 1] FORCE RESET & ROUTE INJECTION"
echo "============================================================"

# 1. 모든 관련 앱 강제 종료
echo "[-] Stopping all related apps..."
adb -s $DEVICE_ID shell "am force-stop $PKG_GPS"
adb -s $DEVICE_ID shell "am force-stop $PKG_MAP"

# 2. 기존 데이터 및 캐시 삭제
echo "[-] Cleaning up old route data..."
rm -f route_library/*.json
adb -s $DEVICE_ID shell "su -c 'rm -f /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml'"

# 3. 새로운 1개의 경로 생성 (Smart Route Generator)
echo "[-] Generating 1 new high-fidelity route for Place: $PLACE_ID"
python3 smart_route_gen.py $PLACE_ID 1

# 4. XML 빌드 (rebuild_xml.py)
echo "[-] Rebuilding SharedPreference XML..."
python3 rebuild_xml.py

# 5. 기기 주입 및 권한 설정 (Critical)
echo "[-] Injecting new identity to device..."
PREFS_FILE="lib/final_1_prefs.xml"
adb -s $DEVICE_ID push "$PREFS_FILE" /sdcard/fixed_prefs.xml >/dev/null 2>&1
adb -s $DEVICE_ID shell "su -c 'cp /sdcard/fixed_prefs.xml /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml'"
adb -s $DEVICE_ID shell "su -c 'chmod 660 /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml'"
adb -s $DEVICE_ID shell "su -c 'chown $UID_VAL:$UID_VAL /data/data/$PKG_GPS/shared_prefs/${PKG_GPS}_preferences.xml'"

# 6. GPS 시뮬레이터 실행 및 UI 자동화 (Reliable ADB Tap Mode)
echo "[-] Launching GPS Emulator..."
adb -s $DEVICE_ID shell "monkey -p $PKG_GPS -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1

echo "[-] Automating UI Sequence (Please do not touch the screen)..."
sleep 4 # 앱 초기 로딩 대기

# 1. 최초 안내 팝업 "확인"
echo "    > Clicking popup OK..."
adb -s $DEVICE_ID shell input tap 929 1293
sleep 1.5

# 2. 사이드 메뉴 열기 (햄버거 버튼)
echo "    > Opening drawer menu..."
adb -s $DEVICE_ID shell input tap 79 175
sleep 1.5

# 3. "북마크" 메뉴 클릭
echo "    > Clicking Bookmarks..."
adb -s $DEVICE_ID shell input tap 428 616
sleep 1.5

# 4. "경로" 탭 클릭
echo "    > Switching to Route tab..."
adb -s $DEVICE_ID shell input tap 575 324
sleep 1.5

# 5. "Target_Route_01" 클릭
echo "    > Selecting Target_Route_01..."
adb -s $DEVICE_ID shell input tap 623 626
sleep 2.5 # 경로 로딩 및 맵 이동 대기

# 6. 메인 화면에서 Play(주행 시작) 버튼 클릭
echo "    > Clicking Play button..."
adb -s $DEVICE_ID shell input tap 539 2089
sleep 1.5

# [NEW] 속도 조절 (슬라이더 클릭 방식)
# 속도 슬라이더 범위: [97,1065][983,1116] 
# 오른쪽 끝(약 900)을 클릭하여 고속 설정
echo "    > Adjusting speed (SeekBar Tap)..."
adb -s $DEVICE_ID shell input tap 195 1090
sleep 1

# 7. "경로 시작" 확인 팝업에서 "시작" 버튼 클릭
echo "    > Confirming Route Start..."
adb -s $DEVICE_ID shell input tap 929 1585

echo "============================================================"
echo " [✓] AUTO-START COMPLETE: GPS Emulator is now driving!"
echo "     Next: 1. Change IP (Airplane mode)"
echo "           2. Run ./start.sh --random"
echo "============================================================"
