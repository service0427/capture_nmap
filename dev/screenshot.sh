#!/bin/bash

# Configuration
DEVICE_ID="RF9XC00EXGM"
SAVE_DIR="dev/screenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PNG_FILENAME="screen_${TIMESTAMP}.png"
XML_FILENAME="screen_${TIMESTAMP}.xml"

mkdir -p $SAVE_DIR

echo "[-] Capturing screen and UI hierarchy from $DEVICE_ID..."
adb -s $DEVICE_ID shell screencap -p /sdcard/screen.png
adb -s $DEVICE_ID pull /sdcard/screen.png $SAVE_DIR/$PNG_FILENAME >/dev/null 2>&1

adb -s $DEVICE_ID shell uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1
adb -s $DEVICE_ID pull /sdcard/window_dump.xml $SAVE_DIR/$XML_FILENAME >/dev/null 2>&1

echo "============================================================"
echo " [✓] Saved: $SAVE_DIR/$PNG_FILENAME"
echo " [✓] Saved: $SAVE_DIR/$XML_FILENAME"
echo "============================================================"
