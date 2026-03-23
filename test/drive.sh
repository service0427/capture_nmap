#!/usr/bin/env python3
import subprocess
import time
import random
import sys

DEVICE_ID = "RF9XC00EXGM"

def set_speed(speed_kmh):
    # km/h를 m/s로 변환
    speed_ms = speed_kmh / 3.6
    cmd = ["adb", "-s", DEVICE_ID, "shell", "su", "-c", f"setprop debug.nmap.speed {speed_ms}"]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("============================================================")
print("   DYNAMIC SPEED CYCLER (50-100 km/h)")
print(f"   Target Device: {DEVICE_ID}")
print("   Interval: 5.0 seconds")
print("============================================================")

try:
    while True:
        target = random.uniform(50.0, 100.0)
        set_speed(target)
        print(f"[*] [{time.strftime('%H:%M:%S')}] Target Speed: {target:.1f} km/h (Injected via Frida)")
        time.sleep(5)
except KeyboardInterrupt:
    print("\n[-] Stopping speed cycler. Cleaning up...")
    subprocess.run(["adb", "-s", DEVICE_ID, "shell", "su", "-c", "setprop debug.nmap.speed ''"])
    print("[✓] Done.")
