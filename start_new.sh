#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
PKG_NAME="com.nhn.android.nmap"

# [NEW] Physical Device Identity Baseline (현재 단말기/앱 조합의 고정 원본값)
# 주의: 안드로이드 8.0+ 에서 SSAID는 앱마다 다르므로, no-filter 로그에서 확인된 실측치를 사용합니다.
echo "[-] Setting Physical Device Baseline (Confirmed)..."

export NMAP_ORIG_SSAID="e6019a5182dfb4d4"
export NMAP_ORIG_ADID="14ff2a58-b085-4b73-9111-1c3986fe257b"
export NMAP_ORIG_IDFV="e5a64b0c-6c96-b815-25c6-1da41b851be5"

# 1. NI 계산 (원본 SSAID의 MD5)
export NMAP_ORIG_NI=$(echo -n "$NMAP_ORIG_SSAID" | md5sum | awk '{print $1}')

# [NEW] Physical Device Hardware Baseline (물리 기기의 고유 제원)
export NMAP_ORIG_MODEL="SM-A165N"
export NMAP_ORIG_BRAND="samsung"
export NMAP_ORIG_OSVER="15"
export NMAP_ORIG_BUILD_ID="AP3A.240905.015.A2"
export NMAP_ORIG_DISPLAY_ID="A165NKSS3BYH1"
export NMAP_ORIG_WIDTH="1080"
export NMAP_ORIG_HEIGHT="2340"
export NMAP_ORIG_DENSITY="2.8125"

# [FDS] Fingerprint 패턴 정의: samsung/a16ks/a16:15/AP3A.240905.015.A2/A165NKSS3BYH1:user/release-keys
export NMAP_ORIG_FINGERPRINT="samsung/a16ks/a16:15/AP3A.240905.015.A2/A165NKSS3BYH1:user/release-keys"

# 2. NLOG_TOKEN 계산 (원본 NI 기반 Base62 변환)
export NMAP_ORIG_TOKEN=$(python3 -c "
ni = '$NMAP_ORIG_NI'
data_bytes = ni[:12].encode('utf-8')
chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
n = 0
for b in data_bytes: n = (n << 8) | (b & 0xff)
res = ''
while n > 0: n, r = divmod(n, 62); res += chars[r]
print(res[::-1] if res else chars[0])
")

echo "    > Orig SSAID: $NMAP_ORIG_SSAID"
echo "    > Orig NI:    $NMAP_ORIG_NI"
echo "    > Orig Token: $NMAP_ORIG_TOKEN"
echo "    > Orig ADID:  $NMAP_ORIG_ADID"
echo "    > Orig IDFV:  $NMAP_ORIG_IDFV"

# Determine Base Directory
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$BASE_DIR" || exit 1

# [NEW] Cleanup old sessions before starting
echo "[-] Cleaning up old sessions..."
pkill -f mitmdump 2>/dev/null
pkill -f "frida -D" 2>/dev/null
adb -s $DEVICE_ID shell am force-stop $PKG_NAME >/dev/null 2>&1
adb -s $DEVICE_ID shell settings put global http_proxy :0 >/dev/null 2>&1
adb -s $DEVICE_ID shell settings delete global http_proxy >/dev/null 2>&1
adb -s $DEVICE_ID reverse --remove tcp:28888 2>/dev/null
sleep 1

# Argument Parsing
NEW_IP=false
RESET_MODE=false
RANDOM_MODE=false
DEVICE_MODE=false
GPS_MODE=false
NO_FILTER=false
TARGET_ID=""
MEMO=""
unset NMAP_SPOOFED_ADID # 이전 세션의 오염 방지

while [[ $# -gt 0 ]]; do
  case $1 in
    --ip|--new-ip) NEW_IP=true; shift ;;
    --reset) RESET_MODE=true; shift ;;
    --device) DEVICE_MODE=true; shift ;;
    --gps) GPS_MODE=true; shift ;;
    --id) TARGET_ID="$2"; shift 2 ;;
    --no-filter) NO_FILTER=true; shift ;;
    --memo) MEMO="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# [NEW] CLI 충돌 검증 및 기본값 로직
if [ "$NO_FILTER" = true ]; then
    RANDOM_MODE=false
    DEVICE_MODE=false
else
    # 식별자 랜덤화만 기본으로 활성화
    RANDOM_MODE=true
fi

# Setup Log Directory with dynamic flags
DATE_STR=$(date +%Y%m%d)
TIME_STR=$(date +%H%M%S)
LOG_SUFFIX=""
[ "$NEW_IP" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-ip"
[ "$RESET_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-reset"
[ "$RANDOM_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-random"
[ "$DEVICE_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-device"
[ "$GPS_MODE" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-gps"
[ -n "$TARGET_ID" ] && LOG_SUFFIX="${LOG_SUFFIX}-id${TARGET_ID}"
[ "$NO_FILTER" = true ] && LOG_SUFFIX="${LOG_SUFFIX}-nofilter"

# [4] Random Identity (로그 디렉토리 생성 전에 프로필 확보)
if [ "$RANDOM_MODE" = true ]; then
    # [NEW] 1. 하드웨어 비교 로그 (Original 표시)
    echo "[-] Original Physical Device Profile:"
    echo "    > DEVICE=$NMAP_ORIG_MODEL | OS=$NMAP_ORIG_OSVER | BUILD=$NMAP_ORIG_BUILD_ID | DISPLAY=$NMAP_ORIG_DISPLAY_ID"

    # [NEW] 2. 랜덤 기기 프로필 호출 (Pending 표시)
    VALID_DEVICES=($(find lib_new/data/devices/ -maxdepth 1 -name "[!_]*.json"))
    if [ ${#VALID_DEVICES[@]} -gt 0 ]; then
        SELECTED_DEVICE=${VALID_DEVICES[$(( RANDOM % ${#VALID_DEVICES[@]} ))]}
        VERSION_INFO=$(python3 <<PYEOF
import json, random
try:
    with open('$SELECTED_DEVICE') as f:
        data = json.load(f)
    if 'software_versions' in data and data['software_versions']:
        v = random.choice(data['software_versions'])
        print(f"DEVICE={data['model']} | OS={v.get('osver','?')} | BUILD={v.get('build_id','?')} | DISPLAY={v.get('display_id','?')}")
    else:
        print("DEVICE=" + data['model'] + " | Error: No software_versions found")
except Exception as e:
    print(f"Error loading device profile: {e}")
PYEOF
)
        echo "[-] Randomized Target Device Profile (Pending Apply):"
        echo "    > $VERSION_INFO"
    fi

    IDENTITY_FILE="$BASE_DIR/lib_new/data/nmap_identities.env"
    
    if [ "$RESET_MODE" = false ] && [ -f "$IDENTITY_FILE" ]; then
        source "$IDENTITY_FILE"
        echo "[*] Reusing Session Identity from cache."
    else
        NEW_SSAID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
        NEW_IDFV=$(cat /proc/sys/kernel/random/uuid)
        NEW_ADID=$(cat /proc/sys/kernel/random/uuid)
        NEW_NI=$(echo -n "$NEW_SSAID" | md5sum | awk '{print $1}')
        NEW_NLOG_TOKEN=$(python3 -c "
ni = '$NEW_NI'
data_bytes = ni[:12].encode('utf-8')
chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
n = 0
for b in data_bytes: n = (n << 8) | (b & 0xff)
res = ''
while n > 0: n, r = divmod(n, 62); res += chars[r]
print(res[::-1] if res else chars[0])
")
        echo "export NEW_SSAID=\"$NEW_SSAID\"" > "$IDENTITY_FILE"
        echo "export NEW_IDFV=\"$NEW_IDFV\"" >> "$IDENTITY_FILE"
        echo "export NEW_ADID=\"$NEW_ADID\"" >> "$IDENTITY_FILE"
        echo "export NEW_NI=\"$NEW_NI\"" >> "$IDENTITY_FILE"
        echo "export NEW_NLOG_TOKEN=\"$NEW_NLOG_TOKEN\"" >> "$IDENTITY_FILE"
        echo "[*] Session Identity Randomized"
    fi
    
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.ssaid $NEW_SSAID"
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.idfv $NEW_IDFV"
    adb -s $DEVICE_ID shell su -c "setprop debug.nmap.adid $NEW_ADID"
    
    export NMAP_SPOOFED_ADID="$NEW_ADID"
    export NMAP_SPOOFED_SSAID="$NEW_SSAID"
    export NMAP_SPOOFED_IDFV="$NEW_IDFV"
    export NMAP_SPOOFED_NI="$NEW_NI"
    export NMAP_SPOOFED_NLOG_TOKEN="$NEW_NLOG_TOKEN"

    echo "[-] Randomized Session Identity Generated:"
    echo "    > Target SSAID: $NMAP_SPOOFED_SSAID"
    echo "    > Target NI:    $NMAP_SPOOFED_NI"
    echo "    > Target Token: $NMAP_SPOOFED_NLOG_TOKEN"
    echo "    > Target ADID:  $NMAP_SPOOFED_ADID"
    echo "    > Target IDFV:  $NMAP_SPOOFED_IDFV"
fi

# 로그 디렉토리 생성
LOG_DIR="logs/${DATE_STR}/${TIME_STR}${LOG_SUFFIX}"
mkdir -p "$LOG_DIR"
export CAPTURE_LOG_DIR="$(realpath "$LOG_DIR")"

echo ""
echo "============================================================"
echo "   [!] SESSION LOG DIRECTORY (Click to Open)"
echo "   --------------------------------------------------------"
echo "   📂 $CAPTURE_LOG_DIR"
echo "============================================================"
echo ""

cleanup() {
    trap '' INT TERM EXIT
    echo -e "\n[!] Stopping processes..."
    kill $(jobs -p) 2>/dev/null
    adb -s $DEVICE_ID shell settings put global http_proxy :0 >/dev/null 2>&1
    adb -s $DEVICE_ID shell settings delete global http_proxy >/dev/null 2>&1
    adb -s $DEVICE_ID reverse --remove tcp:28888 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

echo "============================================================"
echo "   NAVER MAP SIMULATOR (v3.1 REFACTORED)"
echo "============================================================"

# [0] Frida Server 자동 관리
FRIDA_RUNNING=$(adb -s $DEVICE_ID shell su -c "ps -A 2>/dev/null | grep frida-server")
if [ -z "$FRIDA_RUNNING" ]; then
    echo "[-] Starting Frida Server..."
    adb -s $DEVICE_ID shell su -c "killall -9 re.frida.helper 2>/dev/null; killall -9 frida-server 2>/dev/null"
    sleep 1
    adb -s $DEVICE_ID shell su -c "/data/local/tmp/frida-server -D"
    sleep 2
    echo "[✓] Frida Server Started."
fi

# [1] IP Rotation
if [ "$NEW_IP" = true ]; then
    echo "[-] Toggling Airplane Mode..."
    adb -s $DEVICE_ID shell settings put global airplane_mode_on 1
    adb -s $DEVICE_ID shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true >/dev/null 2>&1
    sleep 3
    adb -s $DEVICE_ID shell settings put global airplane_mode_on 0
    adb -s $DEVICE_ID shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false >/dev/null 2>&1
    
    # [FIX] 실제 데이터 연결 확인 (최대 30초)
    echo "[-] Waiting for network connectivity..."
    for i in $(seq 1 30); do
        # dumpsys connectivity에서 MOBILE CONNECTED + VALIDATED 확인
        NET_STATE=$(adb -s $DEVICE_ID shell dumpsys connectivity 2>/dev/null | grep -E "MOBILE.*CONNECTED" | grep "VALIDATED" | head -1)
        if [ -n "$NET_STATE" ]; then
            echo "[✓] Network connected after ${i}s"
            sleep 2  # 안정화 여유
            break
        fi
        if [ $i -eq 30 ]; then
            echo "[!] Network timeout (30s). Proceeding anyway..."
        fi
        sleep 1
    done
fi

# [2] GPS Simulation
if [ "$GPS_MODE" = true ]; then
    echo "[-] Preparing fresh GPS route for ID: ${TARGET_ID:-Default}..."
    rm -f route_library/*.json 2>/dev/null
    python3 lib_new/utils/smart_route_gen.py $TARGET_ID
    
    if [ -f "route_library/Target_Route_01.json" ]; then
        adb -s $DEVICE_ID push route_library/Target_Route_01.json /data/local/tmp/Target_Route_01.json >/dev/null 2>&1
        bash ./lib_new/utils/reset_and_inject.sh $TARGET_ID
        sleep 3
    else
        echo " [!] Failed to generate route. Skipping GPS."
    fi
fi

# [3] Data Management (Reset Logic)
if [ "$RESET_MODE" = true ]; then
    echo "[-] Performing Absolute Data Purge (Fresh Install State)..."
    adb -s $DEVICE_ID shell am force-stop $PKG_NAME
    adb -s $DEVICE_ID shell su -c "find /data/data/$PKG_NAME -mindepth 1 -maxdepth 1 ! -name 'lib' -exec rm -rf {} +"
    echo "[✓] App Data Nuked (Preserving native libs). Ready for Fresh Identity."
fi

# [5] Network Mode (Always MITM)
MITM_LOG="$LOG_DIR/mitm.log"
PYTHONWARNINGS=ignore nohup mitmdump -s lib_new/mitm_addon.py -p 28888 \
    --ssl-insecure --listen-host 0.0.0.0 --set flow_detail=0 \
    --set validate_inbound_headers=false \
    --ignore-hosts '(?i)pstatic\.net' \
    --ignore-hosts '(?i)tivan\.naver\.com' \
    --ignore-hosts '(?i)facebook\.com' \
    --ignore-hosts '(?i)gstatic\.com' \
    --ignore-hosts '(?i)veta\.naver\.com' \
    --ignore-hosts '(?i)ad\.naver\.com' \
    > "$MITM_LOG" 2>&1 &
sleep 2
adb -s $DEVICE_ID reverse tcp:28888 tcp:28888
adb -s $DEVICE_ID shell settings put global http_proxy localhost:28888
adb -s $DEVICE_ID shell su -c 'iptables -I OUTPUT -p udp --dport 443 -j DROP'

# [6] Launch Naver Map via Frida
HOOK_OPTS="-l lib_new/hooks/_core_survival.js"
HOOK_OPTS="$HOOK_OPTS -l lib_new/hooks/network_hook.js"
if [ "$NO_FILTER" = false ]; then
    HOOK_OPTS="$HOOK_OPTS -l lib_new/hooks/bypass.js"
fi

nohup frida -D $DEVICE_ID --runtime=v8 -f $PKG_NAME \
    $HOOK_OPTS \
    --no-auto-reload > "$LOG_DIR/frida_injection.log" 2>&1 &


echo "[✓] ORIGINAL SYSTEM RESTORED & READY."
wait
