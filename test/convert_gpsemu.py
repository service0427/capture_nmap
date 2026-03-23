import json
import glob
import os

# 파일 경로 설정
input_files = sorted(glob.glob("route_library/달빛잔기지떡_*.json"))
output_file = "food_routes.gpsemu"

def convert_to_gpsemu(json_files, output_path):
    with open(output_path, "w", encoding="utf-8") as out:
        for i, file_path in enumerate(json_files):
            with open(file_path, "r") as f:
                coords = json.load(f) # [[lat, lng], ...]
            
            # gpsemu 좌표 문자열 생성: "lat,lng;lat,lng;..."
            coord_str = ";".join([f"{lat},{lng}" for lat, lng in coords])
            
            # 헤더 구성 (샘플 형식을 따름): 
            # food_01_1_20260321+1+60.0+0.0+좌표데이터
            name = f"food_{i+1:02d}"
            header = f"###\n{name}_1_20260321+1+60.0+0.0+"
            
            out.write(header + coord_str + "\n")
            print(f"[✓] Converted: {os.path.basename(file_path)} -> {name}")

if __name__ == "__main__":
    if input_files:
        convert_to_gpsemu(input_files, output_file)
        print(f"\n[SUCCESS] Unified export file created: {output_file}")
    else:
        print("[!] No JSON files found in route_library/")
