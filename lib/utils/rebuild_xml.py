import json
import glob
import os

# 현재 위치: lib/utils/rebuild_xml.py
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(BASE_DIR))

LIB_DIR = os.path.join(PROJECT_ROOT, "lib")
ROUTE_DIR = os.path.join(PROJECT_ROOT, "route_library")

# 최신 생성된 주행 경로 파일 가져오기
json_files = sorted(glob.glob(os.path.join(ROUTE_DIR, "*.json")), key=os.path.getmtime, reverse=True)
output_path = os.path.join(LIB_DIR, "final_1_prefs.xml")

def build_xml(route_jsons):
    # 1. 고정 마크 및 자동 활성화를 위한 필수 플래그들
    entries = [
        '    <boolean name="noads" value="true" />',
        '    <boolean name="onettimeblock" value="true" />',
        '    <int name="pagbookmark" value="1" />', # 경로 탭 우선
        '    <int name="accion" value="0" />'
    ]
    
    if route_jsons:
        with open(route_jsons[0], "r") as f:
            coords = json.load(f)
        
        coord_str = ";".join([f"{lat},{lng}" for lat, lng in coords]) + ";"
        
        # [핵심] ruta0 에 새로운 경로를 꽂아넣어 첫 번째 순위로 강제 고정
        # 형식: 이름 + 즐겨찾기(1) + 속도 + 고도 + 좌표
        display_name = "Target_Route_01"
        value = f"{display_name}+1+60.0+0.0+{coord_str}"
        
        entries.append(f'    <string name="ruta0">{value}</string>')
        
        # 마지막 위치(lastloc)도 경로의 시작점으로 강제 일치시켜서 지도 즉시 이동 유도
        start_pt = f"{coords[0][0]},{coords[0][1]}"
        entries.append(f'    <string name="lastloc">Current_Start+{start_pt}+15.0</string>')

    xml_content = "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n"
    xml_content += "\n".join(entries)
    xml_content += "\n</map>"
    
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(xml_content)

if __name__ == "__main__":
    build_xml(json_files)
    print(f"[SUCCESS] High-Fidelity XML rebuilt at: {output_path}")
