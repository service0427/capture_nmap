#!/bin/bash

# Configuration (DEV VERSION v13.1)
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"

echo "============================================================"
echo "   NAVER MAP SIMULATOR (v3.1 DEV - File Based Engine)"
echo "============================================================"

# 1. 경로 데이터 생성 (Python 유틸)
python3 lib/utils/smart_route_gen.py 1889658893 1 > /dev/null

# 2. JSON 경로 파일을 기기의 임시 폴더로 전송 (권한 777 부여)
echo "[-] Pushing Route File to Device..."
adb -s $DEVICE_ID push route_library/Target_Route_01.json /data/local/tmp/target_route.json > /dev/null 2>&1
adb -s $DEVICE_ID shell chmod 777 /data/local/tmp/target_route.json
echo "[✓] Route File Ready at /data/local/tmp/."

# 3. 앱 초기화 (Identity & History Reset)
adb -s $DEVICE_ID shell am force-stop $PKG_NAME
adb -s $DEVICE_ID shell su -c "rm -rf /data/data/$PKG_NAME/shared_prefs/*"
adb -s $DEVICE_ID shell su -c "rm -rf /data/data/$PKG_NAME/databases/*"

# 4. 앱 실행 (개발용 Hook 로드)
echo "[-] Launching App with Native Movement Engine..."
# --no-pause 대신 spawn 후 바로 resume 하도록 frida 명령어 최적화
frida -D $DEVICE_ID --runtime=v8 -f $PKG_NAME \
    -l lib/hooks/bypass.js \
    -l lib/hooks/network_hook.js \
    -l lib/hooks/location_hook_dev.js \
    -l lib/hooks/sensor_hook.js \
    --no-auto-reload
