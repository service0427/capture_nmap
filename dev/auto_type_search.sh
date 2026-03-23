#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
SEARCH_QUERY="달빛잔기지떡"

echo "============================================================"
echo "   🚀 NAVER MAP SMART SEARCH (Deep Link Mode)"
echo "   Query: $SEARCH_QUERY"
echo "============================================================"

# 1. 딥링크를 이용한 검색어 주입 및 실행
# nmap://search?query={검색어} 프로토콜 사용
echo "[-] Sending Search Intent..."
adb -s $DEVICE_ID shell am start -a android.intent.action.VIEW -d "nmap://search?query=$SEARCH_QUERY" >/dev/null 2>&1

# 2. 로딩 대기
echo "[-] Waiting for search results to load..."
sleep 3

echo "============================================================"
echo " [✓] SEARCH COMPLETED VIA DEEP LINK."
echo "============================================================"
