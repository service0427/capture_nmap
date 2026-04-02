# Naver Map High-Fidelity Simulation System (v3.0 Final)

## 🎯 프로젝트 개요 (Project Overview)
본 프로젝트는 네이버 지도 안드로이드 앱의 고충실도 시뮬레이션 및 데이터 캡처 시스템입니다. 수많은 시행착오 끝에 **OS 최하단(Native)과 자바 프레임워크(Java)를 통합 지배**하는 단일화된 우회 아키텍처를 완성했습니다.

## 🏗 핵심 아키텍처 (System Architecture)

### 1. 통합 마스터 엔진 (`lib/hooks/bypass.js`)
- **Native Guard**: `libc.so`의 `write`, `send` 시스템 콜을 직접 가로채어 커널로 나가는 패킷 버퍼에서 원본 식별자를 실시간 세탁.
- **Java Identity Monolith**: `Map`, `JSONObject`, `Bundle`, `SharedPreferences` 등 모든 데이터 컨테이너를 통합 관리하여 식별자 정합성(Symmetry) 100% 보장.
- **Identity Patterns**: ADID(UUID), SSAID(16-hex), NI(32-hex), nlog_id(16-mixed) 패턴을 실제 기기와 완벽히 동일하게 재현.

### 2. 시뮬레이션 및 우회 레이어
- **`location_hook.js`**: 물리적 오차(Jitter)가 포함된 GPS 좌표 주입.
- **`sensor_hook.js`**: 주행 상태에 따른 가속도/자이로 센서 노이즈 주입.
- **`network_hook.js`**: SSL Pinning 우회 및 트래픽 분석.

## 🚀 주요 워크플로우 (Development Workflows)

### 1. 시뮬레이션 실행 (Execution)
```bash
# 시나리오 기반 전체 사이클 실행 (기기 변조, 랜덤 아이덴티티, GPS 포함)
./start.sh --reset --random --device SM-S921N --gps
```

### 2. 식별자 무결성 규칙 (Identity Rules)
- 모든 식별자는 단일 세션 내에서 **고정 및 동기화**되어야 함.
- 가짜 데이터 주입 시 원본 데이터 타입(Long, String 등)을 반드시 보존할 것 (evts 배열 유실 방지).

## 🚨 개발 원칙 및 금기 사항 (Mandates)
1. **No Multiple Scripts**: 우회 로직은 반드시 `bypass.js` 하나로 통합 관리하며, 충돌을 방지한다.
2. **Core Dominance**: 클래스 이름에 의존하는 후킹보다 데이터의 패턴(UUID, Hex)을 보고 타격하는 코어 방식을 지향한다.
3. **Stability First**: 모든 후킹에는 재귀 방지 플래그(`entering`)와 `try-catch`를 적용하여 앱 크래시를 원천 차단한다.

---
*Last Updated: 2026-03-25 (Identity Symmetry & Core Integration Completed)*
