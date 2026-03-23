# 📘 Smart Route Guide

## 1. 개요
특정 매장(Place ID)을 중심으로 하는 실제 주행 경로를 대량 생성하고, GPS 시뮬레이터 앱(`com.rosteam.gpsemulator`)에 자동으로 주입하는 자동화 시스템입니다.

## 2. 주요 실행 명령
- **기본 실행 (달빛잔기지떡 기준 10개)**:
  ```bash
  ./add_food_routes.sh
  ```
- **특정 매장으로 경로 갱신**:
  ```bash
  ./add_food_routes.sh {PLACE_ID}
  ```

## 3. 핵심 도구 설명
- **`smart_route_gen.py`**: 네이버 내비 엔진(`drive.io.naver.com`) v3를 호출하여 실제 도로를 따라가는 PBF 데이터를 수집하고 `[lat, lng]` 배열로 복원합니다.
- **`rebuild_xml.py`**: 수집된 좌표 파일들을 읽어 `SharedPreference` XML 규격에 맞게 병합합니다. (`ruta0`~`ruta10` 생성)
- **`add_food_routes.sh`**: 전체 공정을 자동화하며, 특히 루팅 권한을 사용하여 기기 내부 데이터 영역에 직접 XML을 이식합니다. (UID 10332 강제 지정)

## 4. 기술 사양
- **경로 방향**: 랜덤 지점 → 매장 (역방향)
- **반경**: 매장 중심 10km 이내 랜덤
- **보안**: 파이썬 기반 HMAC-SHA1 시그니처 자동 생성
- **저장**: 안드로이드 앱 내부 저장소 직접 수정 (재부팅 불필요)

## 5. 관리 포인트
- **UID**: 앱 재설치 시 UID가 변경될 수 있습니다. (현재 10332)
- **Place ID**: 네이버 맵 주소창이나 상세페이지에서 확인 가능합니다.
