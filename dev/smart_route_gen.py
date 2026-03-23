import requests
import hmac
import hashlib
import base64
import time
import urllib.parse
import random
import math
import json
import os

class NaverCrypto:
    @staticmethod
    def generate_drive_hmac(url, timestamp_ms=None):
        KEY_DRIVE_ENCRYPT = b"fvOvQAZ5fvDMvQqiQ6KTZYpPkGhr0oQp653TDil12acO5wnhvIQhl5veOvjoku0H"
        msgpad = str(timestamp_ms if timestamp_ms else int(time.time() * 1000))
        payload = (url[:255] + msgpad).encode('utf-8')
        h = hmac.new(KEY_DRIVE_ENCRYPT, payload, hashlib.sha1).digest()
        md = "v0:" + base64.b64encode(h).decode('utf-8')
        return msgpad, md

class RouteDecoder:
    @staticmethod
    def decode_json_path(coords_array):
        if not coords_array or len(coords_array) < 2: return []
        pts = []
        curr_x, curr_y = coords_array[0], coords_array[1]
        pts.append([float(curr_y) / 10000000.0, float(curr_x) / 10000000.0])
        for i in range(2, len(coords_array), 2):
            if i + 1 < len(coords_array):
                curr_x += coords_array[i]; curr_y += coords_array[i+1]
                pts.append([float(curr_y) / 10000000.0, float(curr_x) / 10000000.0])
        return pts

def get_place_info(place_id):
    if str(place_id) == "1889658893":
        return "달빛잔기지떡", 126.6721551, 37.6428285
    return f"Place_{place_id}", 127.0, 37.5

def get_random_point(lat, lng, radius_km):
    radius_deg = radius_km / 111.0
    u, v = random.random(), random.random()
    w = radius_deg * math.sqrt(u); t = 2 * math.pi * v
    return lat + w * math.sin(t), lng + (w * math.cos(t)) / math.cos(math.radians(lat))

def generate_routes(place_id, count=10):
    name, store_lng, store_lat = get_place_info(place_id)
    print(f"[*] Starting Intelligent Generation: {name} (Speed-Aware)")
    
    LIB_DIR = "route_library"
    os.makedirs(LIB_DIR, exist_ok=True)
    
    success_count = 0
    attempt = 0
    while success_count < count and attempt < 100:
        attempt += 1
        start_lat, start_lng = get_random_point(store_lat, store_lng, 10.0)
        
        base_url = "https://drive.io.naver.com/v3/global/driving"
        # 지능형 데이터를 위해 output=json 사용
        params = {
            "mainoption": "traoptimal",
            "rptype": "4",
            "start": f"{start_lng},{start_lat}",
            "goal": f"{store_lng},{store_lat}",
            "uuid": "85441208bbd688a8ca5a1bc0d2d230d",
            "caller": "mapmobileapps_Android_35_app6.4.0.7_fw2.12.6",
            "lang": "ko",
            "output": "json", # JSON으로 상세 정보 획득
            "respversion": "9"
        }
        full_url = f"{base_url}?{urllib.parse.urlencode(params)}"
        msgpad, md = NaverCrypto.generate_drive_hmac(full_url)
        headers = {
            "x-hmac-msgpad": msgpad, "x-hmac-md": md,
            "user-agent": "ktor-client", "referer": "client://NaverMap"
        }
        
        try:
            resp = requests.get(full_url, headers=headers, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                route_data = data.get('route', {}).get('traoptimal', [{}])[0]
                legs = route_data.get('legs', [])
                
                if legs:
                    intelligent_route = []
                    total_dist = 0
                    total_dur = 0
                    
                    for leg in legs:
                        for step in leg.get('steps', []):
                            # 각 마디(Step)별 거리와 시간 추출
                            step_dist = step.get('distance', 0)
                            step_dur = step.get('duration', 0)
                            
                            # 속도 계산 (km/h)
                            if step_dur > 0:
                                step_speed = (step_dist / step_dur) * 3.6
                            else:
                                step_speed = 30.0 # 기본값
                            
                            # 해당 마디의 좌표들 추출
                            path_data = step.get('path', [])
                            pts = RouteDecoder.decode_json_path(path_data)
                            
                            for pt in pts:
                                # 좌표와 함께 권장 속도 저장
                                intelligent_route.append({
                                    "c": pt, # Coordinate [lat, lng]
                                    "s": round(step_speed, 1) # Target Speed (km/h)
                                })
                            
                            total_dist += step_dist
                            total_dur += step_dur
                    
                    if intelligent_route:
                        filename = f"{name}_{success_count+1:02d}_{total_dist}m_{total_dur//60}m.json".replace(" ", "")
                        with open(f"{LIB_DIR}/{filename}", "w") as f:
                            json.dump(intelligent_route, f)
                        print(f" [✓] Created Intelligent Route: {filename} (Points: {len(intelligent_route)})")
                        success_count += 1
            else:
                print(f" [!] API Error {resp.status_code}")
        except Exception as e:
            print(f" [!] Error: {e}")
        time.sleep(0.5)

    print(f"\n[DONE] Generated {success_count} Intelligent routes.")

if __name__ == "__main__":
    generate_routes("1889658893", 10)
