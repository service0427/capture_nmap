import json
import glob
import os

# 경로 절대 기준 설정 (프로젝트 루트 기반)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# 만약 dev 폴더 안에 있다면 한 단계 위로
if os.path.basename(BASE_DIR) == 'dev':
    PROJECT_ROOT = os.path.dirname(BASE_DIR)
else:
    PROJECT_ROOT = BASE_DIR

LIB_DIR = os.path.join(PROJECT_ROOT, "lib")
ROUTE_DIR = os.path.join(PROJECT_ROOT, "route_library")

# 원본 데이터 (test0001)
original_ruta0 = "test0001+1+15.0+0.0+37.64283764640873,126.65699522942303;37.642834,126.657149;37.64267,126.657143;37.642422,126.657085;37.642377,126.657498;37.642307,126.658087;37.642225,126.658515;37.642145,126.658813;37.642004,126.659216;37.641877,126.659561;37.641774,126.659855;37.641117,126.660981;37.640758,126.661595;37.640595,126.661885;37.64002,126.662941;37.639246,126.664344;37.639043,126.6647;37.639144,126.66478;37.639366,126.664993;37.639674,126.665242;37.639944,126.665468;37.640823,126.666294;37.641052,126.666513;37.641138,126.666513;37.641249,126.66669;37.641721,126.667093;37.642031,126.667395;37.642389,126.66771;37.64306,126.668273;37.643939,126.669037;37.644023,126.669113;37.644905,126.669861;37.644723,126.670215;37.644389,126.669916;37.644147,126.669695;37.64411,126.669688;37.64408,126.669697;37.644051,126.669723;37.643351,126.670981;37.642659,126.672234;37.642648,126.672271;"

# 최신 1개만
json_files = sorted(glob.glob(os.path.join(ROUTE_DIR, "*.json")), key=os.path.getmtime, reverse=True)
output_path = os.path.join(LIB_DIR, "final_1_prefs.xml")

def build_xml(original_data, route_jsons):
    entries = [f'    <string name="ruta0">{original_data}</string>']
    if route_jsons:
        with open(route_jsons[0], "r") as f:
            coords = json.load(f)
        coord_str = ";".join([f"{lat},{lng}" for lat, lng in coords]) + ";"
        display_name = "Target_Route_01"
        value = f"{display_name}+1+60.0+0.0+{coord_str}"
        entries.append(f'    <string name="ruta1">{value}</string>')
    
    xml_content = "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n"
    xml_content += "\n".join(entries)
    xml_content += "\n</map>"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(xml_content)

if __name__ == "__main__":
    build_xml(original_ruta0, json_files)
    print(f"[SUCCESS] XML rebuilt at: {output_path}")
