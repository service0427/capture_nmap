#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"

echo "============================================================"
echo "   [NETWORK RESTORE] COMPATIBILITY MODE (API 35)"
echo "============================================================"

# 1. 비행기 모드를 이용한 강력한 라디오 리셋
echo "[-] 1. Hard Resetting Radio (Airplane Mode Method)..."
adb -s $DEVICE_ID shell su -c "settings put global airplane_mode_on 1"
adb -s $DEVICE_ID shell su -c "am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true"
sleep 3
adb -s $DEVICE_ID shell su -c "settings put global airplane_mode_on 0"
adb -s $DEVICE_ID shell su -c "am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false"
echo "[✓] Radio signal reset."
sleep 10 # 네트워크 복구 대기

# 2. 테더링(Hotspot) 강제 활성화 (다각도 시도)
echo "[-] 2. Attempting to Start Hotspot..."

# 방법 A: svc 명령어 (지원되는 경우)
adb -s $DEVICE_ID shell su -c "svc wifi hotspot set enabled" 2>/dev/null

# 방법 B: Connectivity Service 직접 호출 (가장 강력함)
# Android 11+ 에서는 0번(WiFi) 테더링 시작 명령어가 보통 33번 혹은 34번 service call입니다.
# 하지만 폰마다 번호가 다르므로, 여기서는 시스템 설정을 직접 건드리는 방식을 병행합니다.
adb -s $DEVICE_ID shell su -c "settings put global soft_ap_timeout_enabled 0" # 타임아웃 방지

# 3. 테더링 설정 화면 강제 실행 및 자동 클릭 (마지막 수단)
echo "[-] 3. Launching Tethering Settings for activation..."
adb -s $DEVICE_ID shell su -c "am start -n com.android.settings/.Settings\\\$TetherSettingsActivity" > /dev/null 2>&1
sleep 2

# 화면에 테더링 스위치가 꺼져있을 경우를 대비해 스위치 위치(보통 상단) 클릭
# 삼성 기기 일반적인 테더링 스위치 좌표 (중앙 상단 근처)
echo "    > Toggling Hotspot switch..."
adb -s $DEVICE_ID shell input tap 900 400 
sleep 1
adb -s $DEVICE_ID shell input tap 900 400 # 한 번 더 (상태 확인용)

# 4. 앱으로 복귀
adb -s $DEVICE_ID shell input keyevent KEYCODE_HOME

echo "============================================================"
echo " [!] Network reset sequence finished."
echo " 테더링 아이콘이 상단바에 떳는지 확인해 주세요."
echo "============================================================"
