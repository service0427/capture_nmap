#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"

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
MEMO=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --ip|--new-ip) NEW_IP=true; shift ;;
    --reset) RESET_MODE=true; shift ;;
    --random) RANDOM_MODE=true; shift ;;
    --device) DEVICE_MODE=true; shift ;;
    --gps) GPS_MODE=true; shift ;;
    --no-mitm|--nomitm) NO_MITM=true; shift ;;
    --memo) MEMO="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Setup Log Directory with dynamic flags
DATE_STR=$(date +%Y%m%d)
TIME_STR=$(date +%H%M%S)
LOG_SUFFIX=""
[ "$NEW_IP" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-ip"
[ "$RESET_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-reset"
[ "$RANDOM_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-random"
[ "$DEVICE_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-device"
[ "$GPS_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-gps"
[ "$NO_MITM" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-nomitm"

LOG_DIR="logs/${DATE_STR}/${TIME_STR}${LOG_SUFFIX}${MEMO:+-}${MEMO}"
mkdir -p "$LOG_DIR"
export CAPTURE_LOG_DIR="$(realpath "$LOG_DIR")"

cleanup() {
    trap '' INT TERM EXIT
    echo -e "\n[!] Stopping processes..."
    kill $(jobs -p) 2>/dev/null
    adb -s $DEVICE_ID shell settings put global http_proxy :0 >/dev/null 2>&1
    adb -s $DEVICE_ID shell settings delete global http_proxy >/dev/null 2>&1
    adb -s $DEVICE_ID reverse --remove tcp:28888 2>/dev/null
    echo "[!] Finished. Logs: $LOG_DIR"
    exit 0
}
trap cleanup INT TERM EXIT

echo "============================================================"
echo "   NAVER MAP SIMULATOR (v3.0 Stable - ORIGINAL)"
echo "   Log Dir: $LOG_DIR"
echo "============================================================"

# [1] IP Rotation
if [ "$NEW_IP" = true ]; then
    echo "[-] Toggling Airplane Mode..."
    adb -s $DEVICE_ID shell settings put global airplane_mode_on 1
    adb -s $DEVICE_ID shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true >/dev/null 2>&1
    sleep 3
    adb -s $DEVICE_ID shell settings put global airplane_mode_on 0
    adb -s $DEVICE_ID shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false >/dev/null 2>&1
    sleep 12
fi

# [2] GPS Simulation (Stable ADB Tap Mode)
if [ "$GPS_MODE" = true ]; then
    bash ./lib/utils/reset_and_inject.sh
    sleep 3
fi

# [3] Data Management (Reset Logic)
if [ "$RESET_MODE" = true ]; then
    echo "[-] Performing Identity & History Reset..."
    adb -s $DEVICE_ID shell am force-stop $PKG_NAME
    adb -s $DEVICE_ID shell su -c "rm -rf /data/data/$PKG_NAME/shared_prefs/*"
    adb -s $DEVICE_ID shell su -c "rm -rf /data/data/$PKG_NAME/databases/*"
    adb -s $DEVICE_ID shell su -c "rm -rf /data/data/$PKG_NAME/app_webview/Local\ Storage/*"
    adb -s $DEVICE_ID shell su -c "rm -rf /data/data/$PKG_NAME/app_webview/IndexedDB/*"
    echo "[✓] Search History & Identity Cleared."
fi

# [4] Random Identity & Device Profile
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.model none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.brand none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.osver none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.build_id none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.display_id none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.density none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.width none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.height none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.storage none" >/dev/null 2>&1
adb -s $DEVICE_ID shell su -c "setprop debug.nmap.ram none" >/dev/null 2>&1

if [ "$RANDOM_MODE" = true ]; then
    NEW_SSAID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
    NEW_IDFV=$(cat /proc/sys/kernel/random/uuid)
    NEW_ADID=$(cat /proc/sys/kernel/random/uuid)
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.ssaid $NEW_SSAID"
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.idfv $NEW_IDFV"
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.adid $NEW_ADID"
fi

if [ "$DEVICE_MODE" = true ]; then
    echo "[-] Picking Random Device Profile..."
    DEVICE_FILES=($(ls lib/data/devices/*.json))
    SELECTED_FILE=${DEVICE_FILES[$(( RANDOM % ${#DEVICE_FILES[@]} ))]}
    COMMANDS=$(python3 -c "
import json, random, sys
with open('$SELECTED_FILE') as f:
    p = json.load(f)
hw = random.choice(p['hardware_options'])
sw = random.choice(p['software_versions'])
props = {'model': p['model'], 'brand': p['brand'], 'osver': sw['osver'], 'build_id': sw['build_id'], 'display_id': sw['display_id'], 'density': p['display']['density'], 'width': p['display']['width'], 'height': p['display']['height'], 'storage': hw['storage_gb'], 'ram': hw['ram_gb']}
for k, v in props.items():
    print(f'adb -s $DEVICE_ID shell su -c \"setprop debug.nmap.{k} \\\"{v}\\\"\"')
")
    eval "$COMMANDS"
    P_MODEL=$(adb -s $DEVICE_ID shell getprop debug.nmap.model)
    echo "    [✓] Profile Loaded: $P_MODEL"
fi

# [5] Network Mode
if [ "$NO_MITM" = false ]; then
    MITM_LOG="$LOG_DIR/mitm.log"
    PYTHONWARNINGS=ignore nohup mitmdump -s lib/mitm_addon.py -p 28888 --ssl-insecure --listen-host 0.0.0.0 --set flow_detail=0 > "$MITM_LOG" 2>&1 &
    sleep 2
    adb -s $DEVICE_ID reverse tcp:28888 tcp:28888
    adb -s $DEVICE_ID shell settings put global http_proxy localhost:28888
    adb -s $DEVICE_ID shell su -c 'iptables -I OUTPUT -p udp --dport 443 -j DROP'
fi

# [6] Launch Naver Map via Frida
nohup frida -D $DEVICE_ID --runtime=v8 -f $PKG_NAME \
    -l lib/hooks/bypass.js \
    -l lib/hooks/network_hook.js \
    -l lib/hooks/location_hook.js \
    -l lib/hooks/sensor_hook.js \
    --no-auto-reload > "$LOG_DIR/frida_injection.log" 2>&1 &

echo "[✓] ORIGINAL SYSTEM RESTORED & READY."
wait
