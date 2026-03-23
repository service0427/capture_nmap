#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM" # 대상 기기 ID
PKG_NAME="com.nhn.android.nmap"

echo "============================================================"
echo "   DEVICE IDENTITY MAKER (Standalone Mode)"
echo "   Target: $DEVICE_ID"
echo "============================================================"

# 1. 랜덤 식별자 생성
NEW_SSAID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
NEW_ADID=$(cat /proc/sys/kernel/random/uuid)
NEW_IDFV=$(cat /proc/sys/kernel/random/uuid)

echo "[-] Generated New Identity:"
echo "    > SSAID: $NEW_SSAID"
echo "    > ADID : $NEW_ADID"
echo "    > IDFV : $NEW_IDFV"

# 2. 시스템 물리적 변경 (Permanent Change)
echo "[-] Applying to Android System..."
adb -s $DEVICE_ID shell settings put secure android_id $NEW_SSAID
# GMS 광고 ID 리셋 (브로드캐스트는 보조적 수단)
adb -s $DEVICE_ID shell am broadcast -a com.google.android.gms.settings.ADS_PRIVACY_RESET >/dev/null 2>&1

# 3. 네이버 앱 데이터 초기화 (캐시 삭제 및 신규 인식 유도)
echo "[-] Clearing App Data to force identity refresh..."
adb -s $DEVICE_ID shell am force-stop $PKG_NAME
adb -s $DEVICE_ID shell pm clear $PKG_NAME

# 4. 권한 자동 재부여 (편의성)
echo "[-] Granting essential permissions..."
adb -s $DEVICE_ID shell pm grant $PKG_NAME android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1
adb -s $DEVICE_ID shell pm grant $PKG_NAME android.permission.READ_PHONE_STATE >/dev/null 2>&1

echo "============================================================"
echo " [✓] SUCCESS: Identity Updated!"
echo "     Next launch of Naver Map will use this new identity."
echo "     (ni will be automatically generated based on SSAID)"
echo "============================================================"
