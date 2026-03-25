# Naver Map High-Fidelity Simulation System (V5 / V2.0 SDK Hub)

## 🎯 프로젝트 개요 (Project Overview)
본 프로젝트는 네이버 지도(Naver Map) 안드로이드 앱의 네트워크 트래픽을 완벽하게 재현(Simulation)하고, 보안 탐지(FDS)를 우회하기 위한 정밀 캡처 및 시뮬레이션 시스템입니다. 
단순한 데이터 수집을 넘어, 앱의 런타임 동작을 물리적 수준(Sensor, Jitter)에서 모방하며, 최신 버전(v5 엔진) 및 차세대 SDK 호스팅 아키텍처(V2.0)를 주력으로 개발하고 있습니다.

## 🏗 핵심 아키텍처 (System Architecture)

### 1. 시뮬레이션 레이어 (Simulation & Hooking)
- **Frida Hooks (`lib/hooks/`)**: 
  - `bypass.js`: 기기 식별자(SSAID, ADID, IDFV) 및 하드웨어 프로필(Model, Brand, OS Ver) 실시간 변조.
  - `location_hook.js`: 물리적 오차(Jitter)가 포함된 GPS 좌표 및 센서 데이터 주입.
- **Device Profile DB (`lib/data/devices/`)**: 실제 기기의 규격(Resolution, RAM, Build ID)을 기반으로 한 프로필 데이터셋.

### 2. 네트워크 및 보안 레이어 (Network & Fidelity)
- **High-Fidelity Requests**: `curl_cffi`를 사용하여 Real Device의 `JA3`, `Akamai` TLS 지문을 완벽하게 재현.
- **Fidelity Guard**: `header_rules.json` 및 `HeaderValidator.py`를 통해 요청 헤더의 순서, 대소문자, 필수 여부를 엄격하게 검증 (`strict_fidelity=True`).

### 3. 차세대 엔진 (V2.0 SDK Hub)
- **Native SDK Hosting**: 실제 APK 내부의 SDK(`navermap-sdk.jar`)를 Java 환경에서 직접 로드하여 구동.
- **Data Symmetry**: SDK의 내부 상태 머신을 그대로 사용하여 100% 데이터 정합성 보장 및 탐지 우회.

## 🚀 주요 워크플로우 (Development Workflows)

### 1. 시뮬레이션 실행 (Execution)
```bash
# 시나리오 기반 전체 사이클 실행 (IP 교체, 기기 변조, GPS 주입 포함)
./start.sh --ip --random --device --gps --memo "test_drive_01"

# 특정 개발 단계(Step 1) 정합성 확인
python3 driving_v5/run.py --step 1 --debug
```

### 2. 로그 및 분석 (Logging & Analysis)
- **Simulator Log**: `logs/YYYYMMDD/HHMMSS/simulator.log` (터미널 출력 및 프로세스 로그).
- **Packet Log**: `mitm_addon.py`를 통해 저장된 개별 패킷 JSON 파일.
- **Analysis**: 종료 시 출력되는 로그 폴더의 절대 경로를 참조하여 `report/` 폴더에 분석 문서 작성.

## 🚨 개발 원칙 및 금기 사항 (Critical Mandates)

1. **Fidelity First**: 헤더 순서나 대소문자 하나라도 틀리면 안 됨. 검증 실패 시 규칙을 무시하기보다 구현을 수정할 것.
2. **No Browser Impersonation**: 절대 브라우저 지문(`chrome110` 등)을 사용하지 말 것. 항상 `REAL_DEVICE_JA3` 유지.
3. **Physical Realism**: 좌표 이동 시 반드시 `Vertical Accuracy` 및 `Altitude Jitter`를 포함하여 0.0 값이 전송되지 않도록 할 것.
4. **Contextual Integrity**: V2.0 개발 시 반드시 `docs/01-plan/` 및 `docs/02-design/`의 설계 문서를 우선 참조할 것.

---
*Last Updated: 2026-03-25 (Focus on High-Fidelity & SDK Hub Strategy)*
