# 네이버 지도 앱 Full Profile Spoofing 고도화 플랜 (v8.0)

## 1. 개요 (Objective)
기존의 모델명, 식별자 위주의 단순 변조를 넘어, 네이버 서버(ntrackersdk 등)가 수집하는 **하드웨어 제원(RAM, 용량, 화면 해상도)까지 완벽하게 변조**하여, 한 대의 테스트 폰이나 에뮬레이터(LDPlayer)로 수십 대의 서로 다른 실제 폰을 모사(High-Fidelity Simulation)하는 것을 목표로 합니다.

## 2. 분석 결과 (App Internal Logic)
`base_decompiled` 소스 코드 분석 결과, 네이버 앱은 다음 항목들을 복합적으로 수집하여 기기 고유성을 검증합니다.
*   **식별자**: SSAID, IDFV(AppSetId), ADID
*   **빌드 메타데이터**: Build.MODEL, Build.ID, Build.DISPLAY, Build.VERSION.RELEASE, SystemProperties
*   **하드웨어 스펙**:
    *   `StatFs`: 전체/가용 디스크 용량 (Block Count 기반)
    *   `ActivityManager.MemoryInfo`: 전체/가용 RAM 용량
    *   `DisplayMetrics`: 화면 해상도(Width/Height) 및 픽셀 밀도(Density)

## 3. 구현 내용 (Implementation Details)

### 3.1. 기기 족보 DB 구축 (`lib/data/device_profiles.json`)
실제 존재하는 기기의 스펙을 그대로 모사한 프로필 데이터베이스를 구성했습니다.
*   **지원 기기**: Galaxy S23 Ultra (SM-S918N), Pixel 7 Pro, Galaxy Z Fold 4 (SM-F946N) 등 5종.
*   **포함 데이터**: 모델명, 브랜드, OS 버전, 실제 빌드 ID, 화면 해상도, Density, 스토리지 용량, RAM 용량.

### 3.2. 구동 스크립트 개편 (`start.sh`)
*   `--device` 옵션 실행 시, `device_profiles.json`에서 랜덤하게 하나의 프로필을 선택합니다.
*   선택된 프로필의 모든 세부 스펙(RAM, 용량 등)을 `debug.nmap.*` 시스템 프로퍼티로 주입합니다.

### 3.3. 궁극의 Frida 엔진 탑재 (`lib/bypass.js` v8.0)
시스템 프로퍼티로 전달받은 하드웨어 스펙을 네이버 앱이 호출할 때 가로채어 가짜 값으로 덮어씁니다.
*   **`hook_hardware_deep()` 추가**:
    *   `ActivityManager.getMemoryInfo` 후킹: 지정된 RAM 용량(예: 12GB)으로 위장.
    *   `StatFs` 후킹: 지정된 스토리지 용량(예: 512GB)으로 위장.
    *   `DisplayMetrics` 후킹: 지정된 해상도(예: 1440x3088) 및 DPI로 위장.

## 4. 기대 효과
이 기능이 적용되면, PC 한 대(또는 에뮬레이터)에서 스크립트를 반복 실행하는 것만으로 네이버 서버에는 **"완전히 다른 하드웨어 스펙을 가진 수십 대의 실제 스마트폰"**이 접속하는 것으로 보이게 되어, 차단 리스크가 극적으로 감소합니다.
