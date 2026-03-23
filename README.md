# Naver Map High-Fidelity Simulation System (v2.5)

네이버 지도 안드로이드 앱의 네트워크 트래픽을 완벽하게 재현하고, 보안 탐지(FDS)를 우회하는 하이-피델리티 시뮬레이션 시스템입니다.

## 🚀 Core Features
- **Identity Spoofing**: SSAID, ADID, IDFV 메모리 실시간 변조.
- **Full Profile Spoofing**: 기기 모델명, 제조사, RAM, 저장공간, 해상도 세트 변조.
- **Natural Jitter Engine**: 물리 법칙에 기반한 좌표, 정확도, 고도, 센서 노이즈 주입.
- **Smart Automation**: IP 자동 교체, 약관 동의 건너뛰기, 딥링크 기반 경로 탐색 자동화.
- **Proxy-less Capture**: MITM 없이 폰 내부에서 헤더를 세탁하는 Standalone 모드 지원.

## 📂 Project Structure
- `bin/`: 실행 스크립트 (`start.sh` 등)
- `core/`: 주행 시뮬레이션 핵심 엔진 (v5)
- `lib/hooks/`: Frida 후킹 스크립트 모음
- `lib/data/`: 기기 프로필 DB 및 설정 파일
- `dev/`: 개발 및 UI 자동화 보조 툴
- `docs/`: 한글 상세 기술 문서

## 🛠 Quick Start
```bash
# 1. 기기 환경 설정 및 주행 시작 (풀 사이클)
./bin/start.sh --ip --random --device --reset --agree --gps

# 2. 고속 대량 운영 모드 (MITM 제외)
./bin/start.sh --random --device --reset --nomitm
```

## ⚠️ Security Notice
본 저장소에는 실제 기기 로그, APK 파일, 개인 토큰 정보가 포함되지 않습니다. 
민감한 정보는 `logs/` 및 `apk/` 폴더에 별도로 보관되며 `.gitignore`에 의해 보호됩니다.
