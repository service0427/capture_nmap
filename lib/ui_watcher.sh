#!/bin/bash
# ============================================================
# UI Watcher v2 - 체계적 시나리오 기반 UI 캡처
# ============================================================
# 사용법: ui_watcher.sh <DEVICE_ID> <LOG_DIR> [INTERVAL=2]
# capture_v2.sh 에서 백그라운드로 실행됨

DEVICE_ID="$1"
LOG_DIR="$2"
INTERVAL="${3:-2}"  # 기본 2초 간격

if [ -z "$DEVICE_ID" ] || [ -z "$LOG_DIR" ]; then
    echo "[ui_watcher] ERROR: DEVICE_ID와 LOG_DIR 인자 필요"
    exit 1
fi

# 저장 디렉토리 생성
UI_DIR="${LOG_DIR}/ui_captures"
mkdir -p "$UI_DIR"

# 디바이스 임시 파일 경로
DEVICE_XML="/sdcard/_ui_watcher_dump.xml"
DEVICE_PNG="/sdcard/_ui_watcher_screen.png"

# 상태 변수
PREV_HASH=""
PREV_ACTIVITY="INIT"
COUNTER=0

# ============================================================
# 1. 공용 디바이스 정보 (1회만 추출)
# ============================================================
echo "[ui_watcher] 디바이스 정보 수집 중..."
{
    RESOLUTION=$(adb -s "$DEVICE_ID" shell wm size 2>/dev/null | grep -oP 'Override size: \K.*' || adb -s "$DEVICE_ID" shell wm size | grep -oP 'Physical size: \K.*')
    DENSITY=$(adb -s "$DEVICE_ID" shell wm density 2>/dev/null | grep -oP 'Override density: \K.*' || adb -s "$DEVICE_ID" shell wm density | grep -oP 'Physical density: \K.*')
    MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model | tr -d '\r')
    ANDROID_VER=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.release | tr -d '\r')
    SDK_VER=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.sdk | tr -d '\r')
    APP_VER=$(adb -s "$DEVICE_ID" shell dumpsys package com.nhn.android.nmap 2>/dev/null | grep "versionName" | head -1 | awk -F'=' '{print $2}' | tr -d '\r')

    cat <<EOF
{
  "device_model": "${MODEL}",
  "android_version": "${ANDROID_VER}",
  "sdk_version": "${SDK_VER}",
  "resolution": "${RESOLUTION}",
  "density_dpi": "${DENSITY}",
  "app_version": "${APP_VER}",
  "capture_start": "$(date '+%Y-%m-%d %H:%M:%S')",
  "interval_sec": ${INTERVAL}
}
EOF
} > "${UI_DIR}/device_info.json"
echo "[ui_watcher] 디바이스 정보 저장 완료: ${UI_DIR}/device_info.json"

# ============================================================
# 현재 Activity 이름 획득 함수
# ============================================================
get_current_activity() {
    # 방법 1: mCurrentFocus에서 현재 Activity 추출 (가장 안정적)
    local focus
    focus=$(adb -s "$DEVICE_ID" shell dumpsys window 2>/dev/null | grep "mCurrentFocus" | grep "com.nhn.android.nmap" | head -1)
    if [ -n "$focus" ]; then
        local activity
        activity=$(echo "$focus" | grep -oP 'com\.nhn\.android\.nmap/\K[^ }]+' | tr -d '\r')
        if [ -n "$activity" ]; then
            echo "$activity" | awk -F'.' '{print $NF}'
            return
        fi
    fi

    # 방법 2: topResumedActivity에서 추출
    local top
    top=$(adb -s "$DEVICE_ID" shell dumpsys activity activities 2>/dev/null | grep "topResumedActivity" | grep "com.nhn.android.nmap" | head -1)
    if [ -n "$top" ]; then
        local activity2
        activity2=$(echo "$top" | grep -oP 'com\.nhn\.android\.nmap/\K[^ }]+' | tr -d '\r')
        if [ -n "$activity2" ]; then
            echo "$activity2" | awk -F'.' '{print $NF}'
            return
        fi
    fi

    # Fallback: XML의 package 속성에서 앱 이름만 추출
    echo "NaverMap"
}

# ============================================================
# cleanup: 디바이스 임시 파일 정리
# ============================================================
cleanup_watcher() {
    adb -s "$DEVICE_ID" shell rm -f "$DEVICE_XML" "$DEVICE_PNG" >/dev/null 2>&1

    # 시나리오 요약 생성
    if [ $COUNTER -gt 0 ]; then
        {
            echo "# UI 캡처 시나리오 요약"
            echo "- 총 화면 변경: ${COUNTER}회"
            START_TIME=$(grep "capture_start" "${UI_DIR}/device_info.json" 2>/dev/null | grep -oP '": "\K[^"]+')
            echo "- 캡처 시작: ${START_TIME}"
            echo "- 캡처 종료: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            echo "## 화면 전환 흐름"
            for dir in "${UI_DIR}"/[0-9]*/; do
                if [ -f "${dir}transition.txt" ]; then
                    DIRNAME=$(basename "$dir")
                    TRANS=$(cat "${dir}transition.txt")
                    echo "- ${DIRNAME}: ${TRANS}"
                fi
            done
        } > "${UI_DIR}/scenario_summary.txt"
    fi

    echo "[ui_watcher] 종료 — 총 ${COUNTER}개 화면 변경 캡처됨"
    exit 0
}
trap cleanup_watcher INT TERM

echo "[ui_watcher] 시작 — 감시 간격: ${INTERVAL}초, 저장: ${UI_DIR}"

# ============================================================
# 메인 감시 루프
# ============================================================
while true; do
    # 1. UI 계층구조 덤프
    adb -s "$DEVICE_ID" shell uiautomator dump "$DEVICE_XML" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        sleep "$INTERVAL"
        continue
    fi

    # 2. XML을 로컬 임시 파일로 가져오기
    LOCAL_TMP_XML="/tmp/_ui_watcher_$$.xml"
    adb -s "$DEVICE_ID" pull "$DEVICE_XML" "$LOCAL_TMP_XML" >/dev/null 2>&1
    if [ ! -f "$LOCAL_TMP_XML" ]; then
        sleep "$INTERVAL"
        continue
    fi

    # 3. MD5 해시 비교
    CURRENT_HASH=$(md5sum "$LOCAL_TMP_XML" | awk '{print $1}')

    if [ "$CURRENT_HASH" != "$PREV_HASH" ]; then
        COUNTER=$((COUNTER + 1))
        SEQ=$(printf "%03d" $COUNTER)
        TIMESTAMP=$(date +%H%M%S)

        # 현재 Activity 이름 획득
        CURRENT_ACTIVITY=$(get_current_activity)

        # 시나리오 폴더 생성
        SCENARIO_DIR="${UI_DIR}/${SEQ}_${TIMESTAMP}_${CURRENT_ACTIVITY}"
        mkdir -p "$SCENARIO_DIR"

        echo "[ui_watcher] #${SEQ} 화면 변경 — ${PREV_ACTIVITY} → ${CURRENT_ACTIVITY} (${TIMESTAMP})"

        # 4. 스크린샷 캡처
        adb -s "$DEVICE_ID" shell screencap -p "$DEVICE_PNG" >/dev/null 2>&1
        adb -s "$DEVICE_ID" pull "$DEVICE_PNG" "${SCENARIO_DIR}/screenshot.png" >/dev/null 2>&1

        # 5. UI XML 저장
        cp "$LOCAL_TMP_XML" "${SCENARIO_DIR}/ui_tree.xml"

        # 6. 전환 기록
        echo "${PREV_ACTIVITY} → ${CURRENT_ACTIVITY}" > "${SCENARIO_DIR}/transition.txt"

        # 7. 클릭 가능 요소 요약 추출 (awk 기반)
        {
            echo "# ${CURRENT_ACTIVITY} — 화면 #${SEQ} (${TIMESTAMP})"
            echo "# 전환: ${PREV_ACTIVITY} → ${CURRENT_ACTIVITY}"
            echo "# 형식: [좌표] class | resource-id | text | content-desc | clickable"
            echo "---"
            grep -oP '<node[^>]+>' "$LOCAL_TMP_XML" | \
            awk -F'"' '{
                for(i=1;i<=NF;i++){
                    if($(i)~/text=$/) t=$(i+1)
                    if($(i)~/resource-id=$/) r=$(i+1)
                    if($(i)~/class=$/) c=$(i+1)
                    if($(i)~/content-desc=$/) d=$(i+1)
                    if($(i)~/bounds=$/) b=$(i+1)
                    if($(i)~/clickable=$/) k=$(i+1)
                }
                if(k=="true" || t!="" || d!=""){
                    printf "[%s] %s | %s | text=\"%s\" | desc=\"%s\" | clickable=%s\n", b, c, r, t, d, k
                }
                t=""; r=""; c=""; d=""; b=""; k=""
            }'
        } > "${SCENARIO_DIR}/elements.txt"

        PREV_ACTIVITY="$CURRENT_ACTIVITY"
        PREV_HASH="$CURRENT_HASH"
    fi

    # 임시 파일 정리
    rm -f "$LOCAL_TMP_XML"

    sleep "$INTERVAL"
done
