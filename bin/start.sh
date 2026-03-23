#!/bin/bash

# ==============================================================================
# NAVER MAP HIGH-FIDELITY SIMULATOR (v2.5 Stable)
# ==============================================================================
# [핵심 매뉴얼]
# 1. 네트워크: 반드시 USB 케이블 연결 상태에서 'adb reverse'를 통한 로컬 터널링 사용.
#    - 폰은 localhost:28888을 바라보고, ADB가 이를 PC의 mitmdump(28888)로 배달함.
#    - PC의 IP가 바뀌어도 아무런 상관이 없는 가장 견고한 방식임.
# 2. 신분 세탁: --random (ID 변조) / --device (기기 모델/버전 변조) 분리 운영.
# 3. 데이터 동의: --agree 사용 시 기존에 추출된 'Clean Data'를 권한(660) 맞춰 강제 주입.
# ==============================================================================

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"
MAIN_ACTIVITY="com.naver.map.LaunchActivity"
# [주의] 이 경로는 반드시 동의가 완료된 스토리지 덤프를 가리켜야 함
AGREE_DUMP_SOURCE="/home/tech/app_map_capture/capture/logs/20260320/141612-reset-agree/storage_dump"

# Determine Base Directory
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$BASE_DIR" || exit 1

# Argument Parsing
NEW_IP=false
RESET_MODE=false
RANDOM_MODE=false
DEVICE_MODE=false
GPS_MODE=false
NO_MITM=false
AGREE_MODE=false
MEMO=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --ip|--new-ip) NEW_IP=true; shift ;;
    --reset) RESET_MODE=true; shift ;;
    --random) RANDOM_MODE=true; shift ;;
    --device) DEVICE_MODE=true; shift ;;
    --gps) GPS_MODE=true; shift ;;
    --no-mitm|--nomitm) NO_MITM=true; shift ;;
    --agree) AGREE_MODE=true; shift ;;
    --memo) MEMO="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Auto-memo generation for log directory naming
[ "$RESET_MODE" = true ] && MEMO="reset${MEMO:+-}$MEMO"
[ "$RANDOM_MODE" = true ] && MEMO="random${MEMO:+-}$MEMO"
[ "$DEVICE_MODE" = true ] && MEMO="device${MEMO:+-}$MEMO"
[ "$GPS_MODE" = true ] && MEMO="gps${MEMO:+-}$MEMO"
[ "$NO_MITM" = true ] && MEMO="nomitm${MEMO:+-}$MEMO"
[ "$AGREE_MODE" = true ] && MEMO="${MEMO}-agree"

# Setup Log Directory
DATE_STR=$(date +%Y%m%d)
TIME_STR=$(date +%H%M%S)
LOG_DIR="logs/${DATE_STR}/${TIME_STR}${MEMO:+-}${MEMO}"
mkdir -p "$LOG_DIR"
export CAPTURE_LOG_DIR="$(realpath "$LOG_DIR")"

# Cleanup on exit
cleanup() {
    trap '' INT TERM EXIT
    echo -e "\n[!] Stopping processes & Cleaning network..."
    kill $(jobs -p) 2>/dev/null
    
    # [중요] 종료 시 반드시 폰의 프록시 설정을 제거해야 일반 인터넷 사용 가능
    adb -s $DEVICE_ID shell settings put global http_proxy :0 >/dev/null 2>&1
    adb -s $DEVICE_ID shell settings delete global http_proxy >/dev/null 2>&1
    adb -s $DEVICE_ID shell su -c 'iptables -D OUTPUT -p udp --dport 443 -j DROP >/dev/null 2>&1'
    adb -s $DEVICE_ID reverse --remove tcp:28888 2>/dev/null
    
    echo "[✓] Environment Restored. Logs: $LOG_DIR"
    exit 0
}
trap cleanup INT TERM EXIT

echo "============================================================"
echo "   NAVER MAP SIMULATOR (v2.5 Stable Engine)"
echo "   MITM INTERCEPTION: $([ "$NO_MITM" = true ] && echo "DISABLED" || echo "ENABLED (via USB Tunnel)")"
echo "   LOG DIRECTORY: $LOG_DIR"
echo "============================================================"

# [Step 1] IP Rotation (LTE망 IP 교체)
if [ "$NEW_IP" = true ]; then
    echo "[-] Toggling Airplane Mode (LTE IP Rotation)..."
    adb -s $DEVICE_ID shell settings put global airplane_mode_on 1
    adb -s $DEVICE_ID shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true >/dev/null 2>&1
    sleep 3
    adb -s $DEVICE_ID shell settings put global airplane_mode_on 0
    adb -s $DEVICE_ID shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false >/dev/null 2>&1
    echo "[-] Waiting for network recovery (15s)..."
    sleep 15
fi

# [Step 2] GPS Simulation (외부 주행 스크립트 트리거)
if [ "$GPS_MODE" = true ]; then
    echo "[-] Initiating GPS Simulation sequence..."
    bash ./dev/reset_and_inject.sh
    sleep 3
fi

# [Step 3] App Reset & Identity Setup
if [ "$RESET_MODE" = true ]; then
    echo "[-] Resetting App Storage & Permissions..."
    adb -s $DEVICE_ID shell pm clear $PKG_NAME
    adb -s $DEVICE_ID shell pm grant $PKG_NAME android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1
    adb -s $DEVICE_ID shell pm grant $PKG_NAME android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
fi

# [Step 4] Random Identifiers & Profile
# setprop 빈 값 오류 방지를 위해 초기화 시 'none' 주입
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.model none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.brand none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.osver none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.build_id none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.density none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.width none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.height none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.storage none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.ram none" >/dev/null 2>&1

if [ "$RANDOM_MODE" = true ]; then
    echo "[-] Generating Random Identity..."
    NEW_SSAID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
    NEW_IDFV=$(cat /proc/sys/kernel/random/uuid)
    NEW_ADID=$(cat /proc/sys/kernel/random/uuid)
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.ssaid $NEW_SSAID"
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.idfv $NEW_IDFV"
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.adid $NEW_ADID"
    echo "    [✓] SSAID: $NEW_SSAID"
fi

if [ "$DEVICE_MODE" = true ]; then
    echo "[-] Picking Random Device from lib/data/devices/..."
    # 폴더 내 모든 JSON 파일 리스트 확보
    DEVICE_FILES=($(ls lib/data/devices/*.json))
    # 랜덤하게 하나 선택
    SELECTED_FILE=${DEVICE_FILES[$(( RANDOM % ${#DEVICE_FILES[@]} ))]}
    
    # Python에서 선택된 파일의 정보를 세트로 추출
    COMMANDS=$(python3 -c "
import json, random, sys
with open('$SELECTED_FILE') as f:
    p = json.load(f)
hw = random.choice(p['hardware_options'])
sw = random.choice(p['software_versions'])

props = {
    'model': p['model'], 'brand': p['brand'], 
    'osver': sw['osver'], 'build_id': sw['build_id'], 'display_id': sw['display_id'],
    'density': p['display']['density'], 'width': p['display']['width'], 'height': p['display']['height'], 
    'storage': hw['storage_gb'], 'ram': hw['ram_gb']
}
for k, v in props.items():
    print(f'adb -s $DEVICE_ID shell su -c \"setprop debug.nmap.{k} \\\"{v}\\\"\"')
")
    eval "$COMMANDS"
    
    P_MODEL=$(adb -s $DEVICE_ID shell getprop debug.nmap.model)
    P_BUILD=$(adb -s $DEVICE_ID shell getprop debug.nmap.display_id)
    echo "    [✓] Profile Loaded: $SELECTED_FILE -> $P_MODEL ($P_BUILD)"
fi

# [Step 5] Agreement Data Injection (약관 동의 자동화)
if [ "$RESET_MODE" = true ] && [ "$AGREE_MODE" = true ]; then
    echo "[-] Injecting Agreement Cache (Skip T&C)..."
    adb -s $DEVICE_ID shell su -c "mkdir -p /data/data/$PKG_NAME/shared_prefs"
    adb -s $DEVICE_ID push "$AGREE_DUMP_SOURCE/shared_prefs" /sdcard/nmap_inject/ > /dev/null 2>&1
    adb -s $DEVICE_ID shell su -c "cp -r /sdcard/nmap_inject/* /data/data/$PKG_NAME/shared_prefs/"
    
    # 권한 설정: 리얼 앱과 동일한 UID 및 660 권한 부여 (매우 중요)
    APP_UID=$(adb -s $DEVICE_ID shell su -c "stat -c %u /data/data/$PKG_NAME" | tr -d '\r')
    [ -z "$APP_UID" ] && APP_UID="10332"
    adb -s $DEVICE_ID shell su -c "chown -R $APP_UID:$APP_UID /data/data/$PKG_NAME/"
    adb -s $DEVICE_ID shell su -c "find /data/data/$PKG_NAME/shared_prefs -type f -exec chmod 660 {} \\;"
    adb -s $DEVICE_ID shell rm -rf /sdcard/nmap_inject
    echo "    [✓] SharedPrefs Injected with UID: $APP_UID"
fi

# [Step 6] Network Interception Setup (MITM)
if [ "$NO_MITM" = true ]; then
    echo "[-] LTE Direct Mode: Ensuring Proxy is Disabled."
    adb -s $DEVICE_ID shell settings put global http_proxy :0 >/dev/null 2>&1
    adb -s $DEVICE_ID shell settings delete global http_proxy >/dev/null 2>&1
else
    echo "[-] Starting MITM Interceptor (USB Tunneling Mode)..."
    MITM_LOG="$LOG_DIR/mitm.log"
    PYTHONWARNINGS=ignore nohup mitmdump -s lib/mitm_addon.py -p 28888 --ssl-insecure --listen-host 0.0.0.0 --set flow_detail=0 > "$MITM_LOG" 2>&1 &
    sleep 3
    
    # [핵심] USB를 통해 폰의 트래픽을 PC로 역전송
    echo "[-] Establishing ADB Reverse Tunnel (localhost:28888)..."
    adb -s $DEVICE_ID reverse tcp:28888 tcp:28888
    adb -s $DEVICE_ID shell settings put global http_proxy localhost:28888
    adb -s $DEVICE_ID shell su -c 'iptables -I OUTPUT -p udp --dport 443 -j DROP'
fi

# [Step 7] Launch Naver Map via Frida
FRIDA_LOG="$LOG_DIR/frida_injection.log"
echo "[-] Spawning App with Frida Stealth Bypass..."
nohup frida -D $DEVICE_ID --runtime=v8 -f $PKG_NAME \
    -l lib/bypass.js \
    -l lib/hooks/network_hook.js \
    -l lib/hooks/location_hook.js \
    -l lib/hooks/sensor_hook.js \
    --no-auto-reload > "$FRIDA_LOG" 2>&1 &

echo "============================================================"
echo " [✓] SIMULATION STARTED SUCCESSFULLY."
echo "============================================================"
wait
