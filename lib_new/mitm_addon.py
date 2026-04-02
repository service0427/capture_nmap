import json
import os
import datetime
import random
import threading
import base64
import sys
from mitmproxy import http

# [DEBUG] 시작 메시지
print("\n" + "="*50)
print("[*] MITM_ADDON.PY LOADING (v16.4 Identity-Targeted)")
print("="*50 + "\n")

# [NEW] Protobuf Decoding Support
try:
    import blackboxprotobuf
    HAS_BLACKBOX = True
    print("[✓] blackboxprotobuf detected.")
except ImportError:
    HAS_BLACKBOX = False
    print("[!] blackboxprotobuf NOT FOUND. Protobuf cleaning disabled.")

class TrafficRecorder:
    def __init__(self):
        self.lock = threading.Lock()
        self.counter = 0
        
        # [FIX] 세션 시작 시 로그 디렉토리를 고정하여 폴더 분산 방지
        self.base_log_dir = os.environ.get("CAPTURE_LOG_DIR")
        if not self.base_log_dir:
            self.base_log_dir = os.path.join("logs", datetime.datetime.now().strftime("%Y%m%d/%H%M%S"))
        
        os.makedirs(self.base_log_dir, exist_ok=True)
        print(f"[*] Logging to: {self.base_log_dir}")
        
        # [NEW] Telemetry Session Offsets (세션 내내 일관된 가짜 하드웨어 상태 유지)
        self.session_storage_offset = random.randint(-1024 * 1024 * 500, 1024 * 1024 * 500) # +/- 500MB
        self.session_boot_offset_ms = random.randint(1000 * 60 * 5, 1000 * 60 * 60 * 24) # 5분 ~ 1일 전 부팅
        self.session_install_offset_sec = random.randint(3600 * 24, 3600 * 24 * 7) # 1일 ~ 7일 전 설치

        # [FILTER] 노이즈 개체 및 도메인
        self.NOISE_PATHS = ["/font/sdf/", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".woff", ".ttf", ".zip", ".mvt"]
        self.NOISE_HOSTS = ["facebook.com", "tivan.naver.com", "pstatic.net", "gstatic.com", "veta.naver.com", "ad.naver.com", "clova.ai"]

    def request(self, flow: http.HTTPFlow):
        """Global Secure Sanitizer: Decode -> Wash -> Encode"""
        
        if os.environ.get("NMAP_NO_FILTER") == "true":
            return

        spoofed_adid = os.environ.get("NMAP_SPOOFED_ADID", "")
        spoofed_ni = os.environ.get("NMAP_SPOOFED_NI", "")
        is_random_mode = bool(spoofed_adid and spoofed_adid != "none")

        # 1. 원본 식별자 매핑 (Global Find & Replace 대상)
        # 이 값들은 고유한 UUID/Hex 값이므로 전체 문자열 치환이 안전합니다.
        IDENTITY_MAP = {}
        if is_random_mode:
            IDENTITY_MAP = {
                os.environ.get("NMAP_ORIG_ADID", "NULL_ADID"): spoofed_adid,
                os.environ.get("NMAP_ORIG_NI", "NULL_NI"): spoofed_ni,
                os.environ.get("NMAP_ORIG_IDFV", "NULL_IDFV"): os.environ.get("NMAP_SPOOFED_IDFV", ""),
                os.environ.get("NMAP_ORIG_SSAID", "NULL_SSAID"): os.environ.get("NMAP_SPOOFED_SSAID", ""),
                os.environ.get("NMAP_ORIG_TOKEN", "NULL_TOKEN"): os.environ.get("NMAP_SPOOFED_NLOG_TOKEN", "")
            }

        def smart_cleanse(obj, is_nlogapp=False):
            if isinstance(obj, dict):
                new_dict = {}
                for k, v in obj.items():
                    # --- A. Telemetry & Hardware Overwrite (Targeted Key Only) ---
                    # 공통 수치(15, 1080 등)는 글로벌 치환 시 패킷이 파괴되므로 키 기반으로만 타격합니다.
                    if k == "storage_size" and isinstance(v, int):
                        new_dict[k] = v + self.session_storage_offset
                    elif k == "last_boot_ts" and isinstance(v, int):
                        new_dict[k] = v - self.session_boot_offset_ms
                    elif k == "install_ts" and isinstance(v, int):
                        new_dict[k] = v - self.session_install_offset_sec
                    elif k == "device_model" or k == "model" or k == "DeviceModel":
                        new_dict[k] = os.environ.get("NMAP_SPOOFED_MODEL", v)
                    elif k == "os_ver" or k == "osVersion" or k == "Platform":
                        # "Android 15" -> "Android 12" 처럼 부분 치환이 필요할 수 있음
                        val = str(v)
                        orig_os = os.environ.get("NMAP_ORIG_OSVER", "")
                        fake_os = os.environ.get("NMAP_SPOOFED_OSVER", "")
                        if orig_os and fake_os:
                            new_dict[k] = val.replace(orig_os, fake_os)
                        else:
                            new_dict[k] = v
                    elif k == "os_build" or k == "build_id" or k == "build":
                        new_dict[k] = os.environ.get("NMAP_SPOOFED_BUILD_ID", v)
                    elif k == "device_sr" or k == "resolution":
                        # 1080x2340 -> 1078x2342
                        new_dict[k] = f"{os.environ.get('NMAP_SPOOFED_WIDTH', '1080')}x{os.environ.get('NMAP_SPOOFED_HEIGHT', '2340')}"
                    else:
                        # --- B. Unique Identity Replacement (Find & Replace) ---
                        # UUID 등 고유 식별자는 하위 구조까지 탐색하며 치환합니다.
                        new_dict[k] = smart_cleanse(v, is_nlogapp)
                return new_dict
            elif isinstance(obj, list): return [smart_cleanse(i, is_nlogapp) for i in obj]
            elif isinstance(obj, str):
                if IDENTITY_MAP:
                    for real, fake in IDENTITY_MAP.items():
                        if len(real) > 6 and real in obj: obj = obj.replace(real, fake)
                return obj
            elif isinstance(obj, bytes):
                if IDENTITY_MAP:
                    for real, fake in IDENTITY_MAP.items():
                        if len(real) > 6:
                            real_b = real.encode('utf-8')
                            fake_b = fake.encode('utf-8')
                            if real_b in obj: obj = obj.replace(real_b, fake_b)
                return obj
            return obj

        # 2. URL 및 헤더 치환
        try:
            flow.request.url = smart_cleanse(flow.request.url)
            for k in flow.request.headers:
                if k.lower() == "user-agent": continue
                flow.request.headers[k] = smart_cleanse(flow.request.headers[k])
        except: pass

        # 3. Body 세탁 (Targeted)
        if flow.request.content:
            path = flow.request.path
            host = flow.request.pretty_host
            is_nlogapp = "nlogapp" in path
            is_nelo = "nelo" in host or "nelo" in path
            
            try:
                content_type = flow.request.headers.get("Content-Type", "").lower()
                
                # 3.1 Protobuf Cleaning
                if ("trafficjam" in path or "x-protobuf" in content_type) and HAS_BLACKBOX:
                    import gzip as _gzip
                    raw_data = flow.request.content
                    is_gzip = raw_data.startswith(b'\x1f\x8b')
                    if is_gzip: raw_data = _gzip.decompress(raw_data)
                    
                    decoded, msg_type = blackboxprotobuf.decode_message(raw_data)
                    if decoded:
                        # [ATTACK] 좌표 필드(1=provider, 5=accuracy, 6=bearing, 7=jitter) 세탁/난수 주입
                        def attack_recursive(o):
                            c = 0
                            if isinstance(o, dict):
                                for k in list(o.keys()):
                                    # [UPGRADE] Fused(5) -> LTE(3) Provider 세탁
                                    if str(k) == "1" and str(o[k]) == "5":
                                        o[k] = 3
                                        c += 1
                                    elif str(k) in ["5", "6", "7"]:
                                        if str(o[k]) in ["1065353216", "1.0", "0", "0.0"]:
                                            o[k] = int(random.randint(1080000000, 1150000000))
                                            c += 1
                                    elif isinstance(o[k], (dict, list)):
                                        c += attack_recursive(o[k])
                            elif isinstance(o, list):
                                for i in o: c += attack_recursive(i)
                            return c
                        
                        washed_fields = attack_recursive(decoded)
                        decoded = smart_cleanse(decoded, is_nlogapp)
                        encoded_payload = blackboxprotobuf.encode_message(decoded, msg_type)
                        if is_gzip: encoded_payload = _gzip.compress(encoded_payload)
                        flow.request.content = bytes(encoded_payload)
                        if washed_fields > 0:
                            print(f"[✓] PROTO WASHED: {path[:30]}... ({washed_fields} fields randomized)")

                # 3.2 JSON Cleaning (NLogApp, NELO, Heartbeat 통합)
                elif "json" in content_type or "nlogapp" in path or "heartbeat" in path or is_nelo:
                    try:
                        body_json = json.loads(flow.request.content.decode('utf-8', 'ignore'))
                        if isinstance(body_json, list):
                            body_json = [smart_cleanse(item, is_nlogapp) for item in body_json]
                        else:
                            body_json = smart_cleanse(body_json, is_nlogapp)
                        
                        flow.request.content = json.dumps(body_json).encode('utf-8')
                        if is_nelo:
                            print(f"[🧼] NELO (DeviceID) Washed: {path[:40]}")
                    except:
                        # JSON 파싱 실패 시 원본 문자열 치환이라도 시도
                        flow.request.content = smart_cleanse(flow.request.content, is_nlogapp)
            except Exception as e:
                print(f"[Error] Payload Wash Failed: {e}")

    def responseheaders(self, flow: http.HTTPFlow):
        content_type = flow.response.headers.get("Content-Type", "").lower()
        if "image" in content_type or "font" in content_type or "video" in content_type:
            flow.response.stream = True
            
        host = flow.request.pretty_host
        is_noise = any(noise_host in host for noise_host in self.NOISE_HOSTS)
        if is_noise and ("protobuf" in content_type or "octet-stream" in content_type):
            flow.response.stream = True

    def response(self, flow: http.HTTPFlow):
        host = flow.request.pretty_host
        path = flow.request.path

        try:
            with self.lock:
                self.counter += 1
                current_seq = self.counter

            is_noise = False
            for noise_host in self.NOISE_HOSTS:
                if noise_host in host: is_noise = True
            for noise in self.NOISE_PATHS:
                if noise in path: is_noise = True

            m = flow.request.method[0].upper()
            clean_path = path.split('?')[0].replace('/', '_').strip('_')
            if not clean_path: clean_path = "root"
            if len(clean_path) > 100: clean_path = clean_path[:100] + "_trunc"
            filename = f"{current_seq:03d}_{m}_{clean_path}.json"
            filepath = os.path.join(self.base_log_dir, filename)

            def try_parse_content(content_bytes, content_type_header, is_noise_flag):
                if not content_bytes: return ""
                ct = content_type_header.lower()
                if "image" in ct or "font" in ct or "video" in ct:
                    return f"<MEDIA_SKIPPED: {len(content_bytes)} bytes>"
                if is_noise_flag and ("protobuf" in ct or "octet-stream" in ct):
                    return f"<NOISE_BINARY_SKIPPED: {len(content_bytes)} bytes>"
                if "json" in ct:
                    try: return json.loads(content_bytes.decode('utf-8'))
                    except: pass
                if "protobuf" in ct or "octet-stream" in ct or "trafficjam" in path:
                    return "base64:" + base64.b64encode(content_bytes).decode('ascii')
                try:
                    text = content_bytes.decode('utf-8')
                    try: return json.loads(text)
                    except: return text
                except:
                    if is_noise_flag: return f"<NOISE_UNPRINTABLE_SKIPPED: {len(content_bytes)} bytes>"
                    return "base64:" + base64.b64encode(content_bytes).decode('ascii')

            record = {
                "seq": current_seq,
                "timestamp": datetime.datetime.now().timestamp(),
                "method": flow.request.method,
                "url": flow.request.url,
                "host": host,
                "path": path,
                "request_headers": dict(flow.request.headers),
                "response_headers": dict(flow.response.headers),
                "status_code": flow.response.status_code,
                "request_body": try_parse_content(flow.request.content, flow.request.headers.get("Content-Type", ""), is_noise),
                "response_body": try_parse_content(flow.response.content, flow.response.headers.get("Content-Type", ""), is_noise)
            }

            # [RESTORED] Protobuf Decoding for logging
            content_type_req = flow.request.headers.get("Content-Type", "").lower()
            if HAS_BLACKBOX and flow.request.content and ("x-protobuf" in content_type_req or "trafficjam" in path):
                try:
                    decoded, _ = blackboxprotobuf.decode_message(flow.request.content)
                    def make_serializable(d):
                        if isinstance(d, dict): return {k: make_serializable(v) for k, v in d.items()}
                        elif isinstance(d, list): return [make_serializable(v) for v in d]
                        elif isinstance(d, bytes):
                            try: return d.decode('utf-8')
                            except: return f"hex:{d.hex()}"
                        return d
                    record["request_body_decoded"] = make_serializable(decoded)
                except: pass

            # [RESTORED] Response Decoding (Driving Path)
            if "/v3/global/driving" in path and flow.response.content and HAS_BLACKBOX:
                try:
                    res_body = flow.response.content
                    if res_body.startswith(b"base64:"):
                        raw_bin = base64.b64decode(res_body[7:])
                        coords = self.try_decode_route(raw_bin)
                        if coords:
                            self.sync_route_to_device(coords, flow.request.timestamp_start)
                            record["response_body_decoded"] = {"type": "driving_path", "path": coords}
                except: pass

            all_packets_path = os.path.join(self.base_log_dir, "all_packets.jsonl")
            with open(all_packets_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")

            if os.environ.get("NMAP_NO_FILTER") != "true":
                if is_noise: return

            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(record, f, ensure_ascii=False, indent=2)
            
            print(f"[Traffic] #{current_seq:03d} [{m}] {host}{path[:40]}... -> {filename}")
                 
        except Exception as e:
            print(f"[Error] Failed to record flow: {e}")

addons = [TrafficRecorder()]
