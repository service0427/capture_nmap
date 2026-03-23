#!/usr/bin/env python3
import json
import os
import time
import subprocess
import glob

DEVICE_ID = "RF9XC00EXGM"
TEST_LAT = 37.123456789
TEST_LNG = 127.123456789
GPS_FILE = "/data/local/tmp/gps.json"

def get_latest_log_dir():
    base_logs = "logs"
    if not os.path.exists(base_logs): return None
    d_dirs = sorted([d for d in glob.glob(os.path.join(base_logs, "*/*")) if os.path.isdir(d)], key=os.path.getmtime, reverse=True)
    return d_dirs[0] if d_dirs else None

def verify():
    print(f"\n[!] GPS 후킹 검증 테스트 시작 (타겟: {TEST_LAT}, {TEST_LNG})")
    
    # 1. Frida 프로세스 확인
    print("[1] Frida 상태 확인 중...")
    try:
        ps = subprocess.check_output(["adb", "-s", DEVICE_ID, "shell", "ps -A | grep frida"], stderr=subprocess.DEVNULL).decode()
        print(f"    - Frida Server: OK\n{ps.strip()}")
    except:
        print("    - [✗] Frida Server가 실행 중이 아닙니다.")

    # 2. 좌표 주입
    print(f"[2] 테스트 좌표 주입 중 -> {GPS_FILE}")
    data = f'{{"lat":{TEST_LAT},"lng":{TEST_LNG},"speed":10.0,"bearing":0.0}}'
    subprocess.run(["adb", "-s", DEVICE_ID, "shell", f"echo '{data}' > {GPS_FILE}"])
    
    # 3. 로그 분석 (네트워크 요청에 반영되었는지 확인)
    log_dir = get_latest_log_dir()
    if not log_dir:
        print("    - [✗] 로그 폴더를 찾을 수 없습니다. start.sh가 실행 중인가요?")
        return

    print(f"[3] 네트워크 로그 모니터링 중... ({log_dir})")
    all_packets_path = os.path.join(log_dir, "all_packets.jsonl")
    
    start_time = time.time()
    found = False
    while time.time() - start_time < 30:  # 30초 동안 감시
        if os.path.exists(all_packets_path):
            with open(all_packets_path, 'r') as f:
                lines = f.readlines()
                for line in reversed(lines):
                    if str(TEST_LAT)[:7] in line or str(TEST_LNG)[:7] in line:
                        print(f"\n[✓] 검증 성공! 서버 전송 데이터에서 조작된 좌표 포착됨.")
                        print(f"    - 감지된 로그: {line[:200]}...")
                        found = True
                        break
        if found: break
        print(".", end="", flush=True)
        time.sleep(2)
    
    if not found:
        print("\n[✗] 검증 실패: 30초간 조작된 좌표가 포함된 네트워크 요청이 없었습니다.")
        print("    - 원인 1: Frida 후킹이 앱에 주입되지 않음 (start.sh 재실행 필요)")
        print("    - 원인 2: 앱이 위치 권한을 거부했거나 위치 정보를 요청하지 않음")

if __name__ == "__main__":
    verify()
