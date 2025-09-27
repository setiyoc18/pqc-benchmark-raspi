#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=/run/power-save-state
LED_DIR="$STATE_DIR/leds"

# 1) Nyalakan kembali HDMI
if command -v vcgencmd >/dev/null 2>&1; then
  # Jika state awal tersimpan dan =1, nyalakan
  if [[ -f "$STATE_DIR/hdmi_state" ]]; then
    if [[ "$(cat "$STATE_DIR/hdmi_state")" == "1" ]]; then
      vcgencmd display_power 1 || true
    fi
  else
    # default: nyalakan
    vcgencmd display_power 1 || true
  fi
fi
if command -v tvservice >/dev/null 2>&1; then
  # Nyalakan back to preferred mode
  tvservice -p || true
  # Re-kick fb (pada stack lama)
  if command -v framebuffer >/dev/null 2>&1; then framebuffer || true; fi
fi

# 2) Pulihkan WiFi/BT
if command -v rfkill >/dev/null 2>&1; then
  rfkill unblock wifi || true
  rfkill unblock bluetooth || true
fi
# Start lagi layanan yang tadinya aktif
if [[ -f "$STATE_DIR/svcs_active" ]]; then
  while read -r svc; do
    systemctl start "$svc" 2>/dev/null || true
  done < "$STATE_DIR/svcs_active"
else
  # fallback: start common services
  systemctl start wpa_supplicant 2>/dev/null || true
  systemctl start bluetooth 2>/dev/null || true
  systemctl start hciuart 2>/dev/null || true
fi

# 3) Pulihkan LED
if [[ -d "$LED_DIR" ]]; then
  for led in /sys/class/leds/*; do
    name=$(basename "$led")
    [[ -w "$led/trigger" && -f "$LED_DIR/${name}.trigger" ]] && cat "$LED_DIR/${name}.trigger" > "$led/trigger" || true
    [[ -w "$led/brightness" && -f "$LED_DIR/${name}.brightness" ]] && cat "$LED_DIR/${name}.brightness" > "$led/brightness" || true
  done
fi

echo "State runtime telah dipulihkan."
