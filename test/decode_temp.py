import json
import base64
import sys
import os

# RouteDecoder 경로 설정
sys.path.insert(0, os.path.abspath('../driving_v5'))
from core.utils.route_decoder import RouteDecoder

input_file = 'logs/20260320/125733-reset/610_G_v3_global_driving.json'
output_file = 'decoded_driving_610.json'

def main():
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
        
        body = data.get("response_body", "")
        if body.startswith("base64:"):
            raw_bytes = base64.b64decode(body[7:])
        else:
            print("No base64 data found.")
            return

        # PBF 해독 (좌표 추출)
        coords = RouteDecoder.decode_pbf_path(raw_bytes)
        
        # 전체 데이터 구조 해독 (BlackboxProtobuf 등 사용 시 더 자세하나, 현재는 가용한 툴 기준)
        result = {
            "source_file": input_file,
            "summary": {
                "total_points": len(coords) if coords else 0,
                "start_coord": coords[0] if coords else None,
                "goal_coord": coords[-1] if coords else None
            },
            "path": coords,
            "raw_meta": {
                "url": data.get("url"),
                "timestamp": data.get("timestamp")
            }
        }

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        
        print(f"Successfully created {output_file} with {len(coords)} coordinates.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
