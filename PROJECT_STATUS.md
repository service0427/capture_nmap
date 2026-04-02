# 📄 Naver Map Simulation Project: Status Report (v3.1)

## 1. 프로젝트 개요
네이버 지도 앱(v6.4.0.7)의 고충실도 시뮬레이션 및 데이터 캡처 시스템. 하드웨어 식별자 변조, SSL Pinning 우회, 센서 노이즈 주입, 그리고 실시간 경로 동기화(Virtual Driver)를 통합 지배함.

## 2. 시스템 아키텍처 (핵심 컴포넌트)

### A. 마스터 컨트롤러 (`start.sh`)
- **역할**: Frida 서버 관리, `mitmproxy` 실행, 환경 변수 정리, 옵션별 훅 로드.
- **주요 기능**: 
    - `--reset`: 앱 데이터 초기화 및 식별자 unset.
    - `--random`: 새로운 가짜 Identity(ADID, SSAID 등) 생성.
    - `--gps`: 시뮬레이션 훅(`location`, `sensor`) 활성화.
    - **Session Cleanup**: 실행 시마다 꼬인 `mitmdump`, `frida` 프로세스 자동 정리 로직 탑재.

### B. 통합 우회 엔진 (`lib/hooks/bypass.js`)
- **Identity Control**: 시스템 프로퍼티(`debug.nmap.*`)를 감지하여 `--random` 모드일 때만 식별자 주입.
- **Security Bypass**: 네이티브 레벨(`libc.so`)에서 시리얼 번호 및 빌드 ID 변조.

### C. 지능형 가상 드라이버 (`lib/hooks/location_hook.js`)
- **Dynamic Route Sync**: 디바이스 내 `/data/local/tmp/current_route.json` 파일을 실시간 감시.
- **Auto-Bearing**: 이동 좌표 간의 각도를 계산하여 차량의 진행 방향(Bearing)을 자동 주입.
- **Humanity Jitter**: 좌표 및 속도에 미세한 가우시안 노이즈를 섞어 FDS 회피.

### D. 물리 시뮬레이터 (`lib/hooks/sensor_hook.js`)
- **Vibration Engine**: 가속도 센서(Z축)에 0.15 수준의 노이즈를 주입하여 노면 진동 재현.
- **Gyro Sync**: 차의 피칭(Pitch)과 롤링(Roll)에 맞춘 자이로스코프 데이터 변조.

### E. 트래픽 분석기 (`lib/mitm_addon.py`)
- **Traffic Interceptor**: 모든 도메인의 패킷을 캡처하여 `jsonl`로 저장.
- **Route Extractor**: 네이버 서버의 `driving` 응답(PBF)을 감지하여 좌표를 추출, 디바이스로 즉시 `adb push`.

## 3. 최근 주요 해결 사항 (Fixed)
1.  **조이스틱 충돌**: 조이스틱 사용 시 `Bundle alignment` 에러로 인한 앱 크래시를 분석하고, Frida 훅과의 간섭을 차단함.
2.  **재탐색(Rerouting) 실패**: `Bearing` 값이 없어 재탐색이 안 되던 문제를 "자동 방위각 계산 로직"으로 해결.
3.  **지도 로딩 오류**: 호스트 필터 제한을 풀어 지도 타일 데이터가 정상 수신되도록 수정.
4.  **세션 오염**: 이전 실행의 환경 변수가 남는 문제를 `unset` 명령어로 해결.
5.  **GPS 좌표 정합성 (Sea-Fix)**: 위도/경도 Swap 현상을 `mitm_addon.py`에서 자동 감지 및 교정하고, `location_hook.js`의 인덱스 불일치 버그를 시간 기반 동기화 로직으로 해결.

## 4. 현재 상태 및 다음 과제
- **현재**: GPS 좌표 정합성 및 자율 주행(Virtual Driver) 동기화 로직 최종 안정화 완료.
- **이슈**: 없음 (주요 정합성 이슈 해결됨).
- **다음 단계**: 대량 데이터 캡처를 위한 자동화 시나리오(`start.sh` 고도화) 및 FDS 탐지 회피용 센서 노이즈 패턴 정교화.

---

### 🛠 관리 도구
- **`dev/kill_joystick.sh`**: 조이스틱 및 가상 위치 앱 강제 종료 및 설정 보존 도구.
- **`dev/screenshot.sh`**: 현재 화면 및 UI 계층 구조 캡처 도구.

---
*Document Created: 2026-03-26*
