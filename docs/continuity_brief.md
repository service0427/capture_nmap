# 📑 [Continuity Brief] 네이버 지도 하이-피델리티 수집 시스템 (루팅폰 집중 단계)

## 1. 현재 환경 및 장치 정보 (Environment)
*   **타겟 기기**: `RF9XC00EXGM` (Samsung SM-A165N, Android 15, **Rooted**)
*   **인프라 상태**: Magisk 설치됨, LSPosed 활성, Frida 서버 가동 중.
*   **주요 도구**:
    *   `start.sh`: MITM(mitmdump), Frida(SSL Bypass/Stealth), UI Watcher 통합 실행.
    *   `route_library/`: 152개 이상의 실제 네이버 주행 데이터 보유 (JSON/GPX).
    *   `hijack_joystick.js`: GPS Emulator 앱의 신호를 가로채는 Catmull-Rom 보간 엔진.

## 2. 주요 성공 및 기술적 요약 (Success Points)
*   **보안 우회 성공**: `isFromMockProvider` 플래그 및 URL 파라미터(`?mock=true`)의 탐지 메커니즘 분석 완료. 루팅폰에서는 LSPosed와 Frida를 통해 완벽한 **은닉(Stealth)** 주행이 가능함.
*   **고정밀 주행 엔진**: 60FPS 급 부드러운 움직임을 보장하는 **Catmull-Rom 보간 알고리즘**이 하이재킹 엔진에 탑재됨.
*   **MITM 가시화**: `apis.naver.com` 및 `nlog.naver.com` 패킷을 실시간으로 캡처하고 분석할 수 있는 체계 구축됨.

## 3. 새로운 미션 및 설계 방향 (New Mission)
*   **수동 제어 중심**: `drive.sh`를 통한 자동화 주행 대신, **앱 내부의 수동 조작(핀 찍기/저장된 경로 실행)**을 기본으로 함.
*   **캡처 정상화 및 자동화**: 
    *   사용자가 앱에서 주행을 시작하면, 이동 경로 동안 발생하는 모든 패킷(Traffic)과 화면(Screenshot)을 **누락 없이 정합성 있게 매칭하여 저장**.
    *   주행 중 "GPS 탐색 중"과 같은 이질적인 UI 요소가 발생하지 않도록 **실시간 은닉 레이어**를 상시 가동.
*   **데이터 라이브러리 자동 확충**: 수동으로 주행한 경로 데이터가 완료 즉시 `route_library/`에 최적화된 포맷으로 자동 저장되는 시스템 구축.

## 4. 다음 단계 작업 리스트 (Immediate Next Steps)
1.  **`start.sh` 기반 상시 관제**: 수동 주행 중 `mitmdump`가 가로챈 `driving.json` 패킷을 실시간으로 감시하여 정밀 좌표로 자동 변환.
2.  **은닉 레이어 최적화**: 수동 주행 중에도 네이버 지도 서버가 눈치채지 못하게 하는 `LocationManager` 전역 후킹 스크립트 상주.
3.  **데이터 무결성 검증**: 수동으로 생성된 경로 데이터가 실제 도로망과 100% 일치(Snap)하는지 확인하는 리포팅 도구 가동.
