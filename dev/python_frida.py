import frida
import time
import sys

def on_message(message, data):
    if message['type'] == 'send':
        print(f"[Frida] {message['payload']}")
    else:
        print(f"[Frida] {message}")

try:
    device = frida.get_device("RF9XC00EXGM")
    process = device.get_process("com.rosteam.gpsemulator")
    # Attach to the running process by PID
    session = device.attach(process.pid)
    
    with open("dev/track_intent.js", "r") as f:
        script_source = f.read()
        
    script = session.create_script(script_source)
    script.on('message', on_message)
    script.load()
    
    print("[*] Python Frida tracker is running. Waiting for events...")
    # Keep running for 30 seconds
    time.sleep(30)
    
except Exception as e:
    print(f"Error: {e}")
