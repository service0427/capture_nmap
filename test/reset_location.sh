#!/bin/bash
echo "[*] GPS 시뮬레이션 종료 및 실제 위치 복구 중..."
adb -s RF9XC00EXGM shell su -c "am force-stop com.rosteam.gpsemulator"
# 가짜 위치 공급자 강제 제거 (안드로이드 시스템 레벨)
adb -s RF9XC00EXGM shell su -c "settings delete secure mock_location_app"
adb -s RF9XC00EXGM shell su -c "settings put secure mock_location_app com.rosteam.gpsemulator" # 권한 유지
echo "[✓] 실제 위치 복구 완료. 네이버 지도를 다시 확인해 보세요."
