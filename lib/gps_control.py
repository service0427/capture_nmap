#!/usr/bin/env python3
"""
GPS 주행 시뮬레이터 v4.3 (Lightweight Mode)
- 초당 5회 전송으로 ADB 프로세스 생성 부하 감소 (0.2s 간격)
- Frida 보간 엔진에 의존하여 부드러움 유지
"""
import sys, os, json, math, time, random, subprocess, glob, base64

DEVICE_ID = os.environ.get("DEVICE_ID", "RF9XC00EXGM")
GPS_INTERVAL = 0.2 # 0.1에서 0.2로 조정 (PC 부하 감소)
GPS_FILE = "/data/local/tmp/gps.json"
SPEED_KMH = 65

def haversine(lat1, lng1, lat2, lng2):
    R = 6371000
    dLat, dLng = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = math.sin(dLat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dLng/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def calc_bearing(lat1, lng1, lat2, lng2):
    dLng = math.radians(lng2 - lng1)
    lat1r, lat2r = math.radians(lat1), math.radians(lat2)
    y = math.sin(dLng) * math.cos(lat2r)
    x = math.cos(lat1r) * math.sin(lat2r) - math.sin(lat1r) * math.cos(lat2r) * math.cos(dLng)
    return (math.degrees(math.atan2(y, x)) + 360) % 360

def random_offset(lat, lng, min_km, max_km):
    dist_km = random.uniform(min_km, max_km)
    angle = random.uniform(0, 2 * math.pi)
    dlat = dist_km / 111.32
    dlng = dist_km / (111.32 * math.cos(math.radians(lat)))
    return lat + dlat * math.cos(angle), lng + dlng * math.sin(angle)

def catmull_rom(p0, p1, p2, p3, t):
    def calc(v0, v1, v2, v3):
        return 0.5 * ((2 * v1) + (-v0 + v2) * t + (2 * v0 - 5 * v1 + 4 * v2 - v3) * t**2 + (-v0 + 3 * v1 - 3 * v2 + v3) * t**3)
    return [calc(p0[0], p1[0], p2[0], p3[0]), calc(p0[1], p1[1], p2[1], p3[1])]

def set_gps(lat, lng, speed=0.0, bearing=0.0):
    data = f'{{"lat":{lat:.9f},"lng":{lng:.9f},"speed":{speed:.2f},"bearing":{bearing:.2f}}}'
    # stderr 무시로 터미널 부하 감소
    subprocess.run(["adb", "-s", DEVICE_ID, "shell", f"echo '{data}' > {GPS_FILE}"], capture_output=True, check=False)

def clear_gps():
    subprocess.run(["adb", "-s", DEVICE_ID, "shell", f"rm -f {GPS_FILE}"], capture_output=True)

def get_real_location():
    try:
        out = subprocess.check_output(["adb", "-s", DEVICE_ID, "shell", "dumpsys", "location"], timeout=5, stderr=subprocess.DEVNULL).decode()
        import re
        match = re.search(r'last location=.*gps\s+(-?\d+\.\d+),(-?\d+\.\d+)', out.lower())
        if match: return float(match.group(1)), float(match.group(2))
    except: pass
    return 37.5665, 126.9780

def decode_route(driving_file):
    try:
        with open(driving_file) as f: body = json.load(f).get("response_body", "")
        if not body: return None
        raw = base64.b64decode(body[7:]) if body.startswith("base64:") else body.encode()
        sys.path.insert(0, os.path.abspath('../driving_v5'))
        from core.utils.route_decoder import RouteDecoder
        return RouteDecoder.decode_pbf_path(raw)
    except: return None

def interpolate_route_curved(coords, speed_mps):
    if len(coords) < 2: return []
    pts = [coords[0]] + coords + [coords[-1]]
    result = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i-1], pts[i], pts[i+1], pts[i+2]
        d = haversine(p1[0], p1[1], p2[0], p2[1])
        if d < 0.001: continue
        steps = max(1, int(d / (speed_mps * GPS_INTERVAL)))
        for s in range(steps):
            t = s / steps
            pos = catmull_rom(p0, p1, p2, p3, t)
            next_pos = catmull_rom(p0, p1, p2, p3, (s+1)/steps) if (s+1) < steps else p2
            bearing = calc_bearing(pos[0], pos[1], next_pos[0], next_pos[1])
            result.append((pos[0], pos[1], bearing))
    return result

def calculate_dynamic_speed(bearing, next_bearing, base_speed_mps):
    diff = abs(next_bearing - bearing)
    if diff > 180: diff = 360 - diff
    speed_factor = max(0.4, 1.0 - (diff / 90.0) * 0.6)
    return base_speed_mps * speed_factor

def main():
    print("\n" + "=" * 50); print("  🚗 GPS 주행 시뮬레이터 v4.3 (Lightweight)"); print("=" * 50)
    real_lat, real_lng = get_real_location()
    
    def jump_random():
        lat, lng = random_offset(real_lat, real_lng, 1.0, 10.0)
        set_gps(lat, lng)
        print(f"\n  [✓] 위치 점프 완료: {lat:.6f}, {lng:.6f}")
        return lat, lng

    jump_random()

    d_dirs = sorted([d for d in glob.glob("logs/*/*") if os.path.isdir(d)], key=os.path.getmtime, reverse=True)
    log_dir = os.environ.get("CAPTURE_LOG_DIR", d_dirs[0] if d_dirs else "")

    while True:
        files = sorted(glob.glob(os.path.join(log_dir, "*_G_v3_global_driving.json")), reverse=True)
        driving_file = None
        for f_path in files:
            try:
                with open(f_path) as f:
                    body = json.load(f).get("response_body", "")
                    if body and len(str(body)) > 200 and "skip" not in str(body).lower():
                        driving_file = f_path; break
            except: continue

        status = f"준비완료: {os.path.basename(driving_file)}" if driving_file else "주행데이터 없음"
        prompt = f"\n  [1:재점프 / 0:종료 / Enter:주행시작]\n  >> "
        
        cmd = input(prompt).strip()
        if cmd == "0": clear_gps(); return
        elif cmd == "1": jump_random(); continue
        elif cmd == "":
            if not driving_file: continue
            break

    print(f"\n  [🚀] 주행 시작: {os.path.basename(driving_file)}")
    coords = decode_route(driving_file)
    if not coords: return

    speed_mps = SPEED_KMH / 3.6
    path = interpolate_route_curved(coords, speed_mps)

    try:
        for i, (lat, lng, bearing) in enumerate(path):
            next_bearing = path[i+1][2] if i < len(path)-1 else bearing
            spd_mps = calculate_dynamic_speed(bearing, next_bearing, speed_mps)
            
            set_gps(lat, lng, spd_mps, bearing)
            
            remain = (len(path) - i) * GPS_INTERVAL
            print(f"\r  [DRIVE {i+1:5d}/{len(path)}] {spd_mps*3.6:4.1f}km/h | 남은:{remain:6.1f}초  ", end="", flush=True)
            
            # Busy-wait 제거, 단순 sleep 사용 (PC 부하 감소)
            time.sleep(GPS_INTERVAL)
                
        print("\n\n  [✓] 주행 완료!")
    finally:
        clear_gps()

if __name__ == "__main__":
    try: main()
    except: clear_gps()
