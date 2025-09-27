#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=/run/power-save-state
mkdir -p "$STATE_DIR"

# ----- Simpan state awal -----
# HDMI state
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd display_power | awk '{print $2}' > "$STATE_DIR/hdmi_state" || echo "0" > "$STATE_DIR/hdmi_state"
elif command -v tvservice >/dev/null 2>&1; then
  # tvservice -s | grep -q "0x12000a" artinya off; kita simpan string status lengkap
  tvservice -s > "$STATE_DIR/hdmi_tvstate" || true
fi

# WiFi/BT rfkill state
if command -v rfkill >/dev/null 2>&1; then
  rfkill list > "$STATE_DIR/rfkill_before" || true
fi

# Layanan terkait
for svc in wpa_supplicant bluetooth hciuart; do
  if systemctl is-active --quiet "$svc"; then
    echo "$svc" >> "$STATE_DIR/svcs_active"
  fi
done

# LED states (simpan trigger & brightness)
LED_DIR="$STATE_DIR/leds"
mkdir -p "$LED_DIR"
for led in /sys/class/leds/*; do
  name=$(basename "$led")
  [[ -r "$led/trigger" ]] && cat "$led/trigger" > "$LED_DIR/${name}.trigger" || true
  [[ -r "$led/brightness" ]] && cat "$led/brightness" > "$LED_DIR/${name}.brightness" || true
done

# ----- Terapkan penghematan daya (runtime) -----
# 1) Matikan HDMI
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd display_power 0 || true
fi
if command -v tvservice >/dev/null 2>&1; then
  tvservice -o || true
fi

# 2) Matikan WiFi & Bluetooth (runtime)
if command -v rfkill >/dev/null 2>&1; then
  rfkill block wifi || true
  rfkill block bluetooth || true
fi
# Hentikan layanan (tanpa disable)
systemctl stop wpa_supplicant 2>/dev/null || true
systemctl stop bluetooth 2>/dev/null || true
systemctl stop hciuart 2>/dev/null || true

# 3) Matikan LED
for led in /sys/class/leds/*; do
  [[ -w "$led/trigger" ]] && echo none > "$led/trigger" || true
  [[ -w "$led/brightness" ]] && echo 0 > "$led/brightness" || true
done

echo "Power save (runtime) diterapkan. Jalankan power_restore_runtime.sh untuk mengembalikan."
