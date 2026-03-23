import json
import os
import datetime
import random
import threading
import base64
from mitmproxy import http

# [NEW] Protobuf Decoding Support
try:
    import blackboxprotobuf
    HAS_BLACKBOX = True
except ImportError:
    HAS_BLACKBOX = False

# 저장할 폴더 구조 결정
env_log_dir = os.environ.get("CAPTURE_LOG_DIR")

if env_log_dir and os.path.exists(env_log_dir):
    BASE_LOG_DIR = env_log_dir
else:
    current_time = datetime.datetime.now()
    DATE_DIR = current_time.strftime("%Y%m%d")
    TIME_DIR = current_time.strftime("%H%M%S")
    BASE_LOG_DIR = os.path.join(os.getcwd(), "logs", DATE_DIR, TIME_DIR)

class TrafficRecorder:
    def __init__(self):
        os.makedirs(BASE_LOG_DIR, exist_ok=True)
        self.lock = threading.Lock()
        self.counter = 0
        self.last_heartbeat_ts = None
        print(f"[MitmRecorder] Log Dir: {BASE_LOG_DIR}")
        if not HAS_BLACKBOX:
            print("[Warning] blackboxprotobuf not found. Decoding will be limited.")

    def request(self, flow: http.HTTPFlow):
        # Heartbeat Monitoring
        if "nlogapp/heartbeat" in flow.request.path:
            now = datetime.datetime.now()
            diff = 0
            if self.last_heartbeat_ts is not None:
                diff = (now - self.last_heartbeat_ts).total_seconds()
            print(f"\n[❤️ HEARTBEAT] Detected at {now.strftime('%H:%M:%S')} (Interval: {diff:.1f}s)")
            self.last_heartbeat_ts = now

    def decode_content(self, content):
        if not content:
            return ""
        try:
            # Try UTF-8 (for JSON/Text)
            text = content.decode('utf-8')
            try:
                return json.loads(text)
            except (json.JSONDecodeError, ValueError):
                return text
        except Exception:
            # Binary data -> Base64
            return f"base64:{base64.b64encode(content).decode('ascii')}"

    def try_decode_protobuf(self, content_str):
        """Attempts to decode base64 protobuf string into a dict"""
        if not content_str or not isinstance(content_str, str) or not content_str.startswith("base64:"):
            return None
        
        if not HAS_BLACKBOX:
            return {"error": "blackboxprotobuf library missing"}

        try:
            raw_data = base64.b64decode(content_str.replace("base64:", ""))
            decoded_dict, message_type = blackboxprotobuf.decode_message(raw_data)
            
            # recursive function to handle bytes in decoded dict
            def sanitize(obj):
                if isinstance(obj, dict):
                    return {str(k): sanitize(v) for k, v in obj.items()}
                elif isinstance(obj, list):
                    return [sanitize(i) for i in obj]
                elif isinstance(obj, bytes):
                    try:
                        return obj.decode('utf-8')
                    except:
                        return f"hex:{obj.hex()}"
                return obj

            return sanitize(decoded_dict)
        except Exception as e:
            return {"error": str(e)}

    # 노이즈 필터 — 이 패턴이 포함된 URL은 저장하지 않음 (필요 시 추가)
    NOISE_PATHS = [
        "/font/sdf/",
    ]
    
    # 노이즈 호스트 — 이 호스트는 저장하지 않음 (필요 시 추가)
    NOISE_HOSTS = [
        "tivan.naver.com",       # 이미지 CDN (광고 배너/썸네일)
    ]

    def request(self, flow: http.HTTPFlow):
        """Global Sanitizer: Outgoing Header Filter"""
        if "User-Agent" in flow.request.headers:
            ua = flow.request.headers["User-Agent"]
            # 리얼 기기 식별 문자열이 포함된 경우 강제 치환
            if "SM-A165N" in ua:
                # 패턴 기반 치환 (삼각형 가드)
                new_ua = ua.replace("SM-A165N", "Pixel-7")
                flow.request.headers["User-Agent"] = new_ua

    def response(self, flow: http.HTTPFlow):
        host = flow.request.pretty_host
        path = flow.request.path
        
        # 호스트 필터 — .naver 가 포함된 호스트만 캡쳐
        if ".naver" not in host:
            return
        
        # 노이즈 호스트 필터
        if host in self.NOISE_HOSTS:
            return
        
        # 노이즈 필터 체크
        for noise in self.NOISE_PATHS:
            if noise in path:
                return

        try:
            with self.lock:
                self.counter += 1
                current_seq = self.counter
            
            safe_path = flow.request.path.split('?')[0].replace('/', '_').strip('_')
            if not safe_path: safe_path = "root"
            if len(safe_path) > 30: safe_path = safe_path[:30]
            
            method_short = "P" if flow.request.method == "POST" else "G"
            filename = f"{current_seq:03d}_{method_short}_{safe_path}.json"
            filepath = os.path.join(BASE_LOG_DIR, filename)

            # Build record
            req_body = self.decode_content(flow.request.content)
            res_content = flow.response.content
            res_body = self.decode_content(res_content)
            res_len = len(res_content) if res_content else 0

            record = {
                "seq": current_seq,
                "timestamp": flow.request.timestamp_start,
                "http_version": flow.request.http_version,
                "method": flow.request.method,
                "url": flow.request.url,
                "host": host,
                "path": flow.request.path,
                "request_headers": dict(flow.request.headers),
                "response_headers": dict(flow.response.headers),
                "response_len": res_len,
                "status_code": flow.response.status_code,
                "request_body": req_body,
                "response_body": res_body
            }
            
            # 1. Add Decoded Body if it's Protobuf (Internal)
            if isinstance(req_body, str) and req_body.startswith("base64:"):
                decoded_data = self.try_decode_protobuf(req_body)
                if decoded_data and "error" not in decoded_data:
                    record["request_body_decoded"] = decoded_data

            # 2. [NEW] Auto-decode driving response (RouteDecoder)
            if "driving" in flow.request.path and isinstance(res_body, str) and res_body.startswith("base64:"):
                try:
                    import sys
                    # 현재 파일(mitm_addon.py) 기준으로 RouteDecoder 절대 경로 계산
                    current_dir = os.path.dirname(os.path.abspath(__file__))
                    v5_path = os.path.abspath(os.path.join(current_dir, '../../driving_v5'))
                    
                    if os.path.exists(v5_path):
                        if v5_path not in sys.path: sys.path.insert(0, v5_path)
                        from core.utils.route_decoder import RouteDecoder
                        
                        raw_bin = base64.b64decode(res_body[7:])
                        coords = RouteDecoder.decode_pbf_path(raw_bin)
                        if coords:
                            record["response_body_decoded"] = {
                                "type": "driving_path",
                                "total_points": len(coords),
                                "path": coords
                            }
                        else:
                            record["response_body_decoded"] = {"error": "RouteDecoder returned empty coordinates"}
                    else:
                        # 또 다른 가능한 경로 체크
                        v5_path_alt = os.path.abspath(os.path.join(current_dir, '../driving_v5'))
                        if os.path.exists(v5_path_alt):
                            if v5_path_alt not in sys.path: sys.path.insert(0, v5_path_alt)
                            from core.utils.route_decoder import RouteDecoder
                            raw_bin = base64.b64decode(res_body[7:])
                            coords = RouteDecoder.decode_pbf_path(raw_bin)
                            if coords:
                                record["response_body_decoded"] = { "type": "driving_path", "total_points": len(coords), "path": coords }
                        else:
                            record["response_body_decoded"] = {"error": f"RouteDecoder path not found: {v5_path}"}
                except Exception as e:
                    record["response_body_decoded"] = {"error": f"RouteDecoder execution failed: {str(e)}"}

            # 3. Save the single unified JSON file
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(record, f, ensure_ascii=False, indent=2)
            
            # 3. Save to integrated log (all_packets.jsonl)
            all_packets_path = os.path.join(BASE_LOG_DIR, "all_packets.jsonl")
            with open(all_packets_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")

            print_time = datetime.datetime.now().strftime("%m%d%H%M%S.%f")[:14]
            print(f"[{print_time}] Saved: {filepath}")
            print(f"[Traffic] {flow.request.method} {flow.request.pretty_url} << {flow.response.status_code}")
                 
        except Exception as e:
            print(f"[Error] Failed to record flow: {e}")

addons = [TrafficRecorder()]
