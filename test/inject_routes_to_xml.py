import json
import glob
import os
import re

# 경로 설정
prefs_path = "lib/com.rosteam.gpsemulator_preferences.xml"
json_files = sorted(glob.glob("route_library/달빛잔기지떡_*.json"))[:5] # 정확히 5개만

def update_prefs(xml_path, route_jsons):
    with open(xml_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # </map> 태그 바로 앞에 새로운 경로 추가
    new_entries = []
    for i, json_path in enumerate(route_jsons):
        with open(json_path, "r") as f:
            coords = json.load(f)
        
        # 형식: 이름+1+60.0+0.0+lat,lng;lat,lng;...;
        coord_str = ";".join([f"{lat},{lng}" for lat, lng in coords]) + ";"
        name = f"food_{i+1:02d}"
        value = f"{name}+1+60.0+0.0+{coord_str}"
        
        entry = f'    <string name="ruta{i+1}">{value}</string>'
        new_entries.append(entry)
        print(f"[✓] Prepared: {name}")

    # XML에 삽입 (기존 ruta1~5가 있으면 덮어쓰거나 새로 추가)
    # 안전하게 </map> 직전에 삽입
    updated_content = content.replace("</map>", "\n".join(new_entries) + "\n</map>")
    
    with open(xml_path, "w", encoding="utf-8") as f:
        f.write(updated_content)

if __name__ == "__main__":
    if os.path.exists(prefs_path) and json_files:
        update_prefs(prefs_path, json_files)
        print("\n[SUCCESS] XML file updated with new routes.")
    else:
        print("[!] Missing prefs file or JSON routes.")
