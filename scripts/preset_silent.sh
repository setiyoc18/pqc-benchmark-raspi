#!/bin/bash

echo " Entering Silent Benchmark Mode..."

# Disable non-essential services
for service in triggerhappy avahi-daemon bluetooth hciuart cups cron rsyslog; do
  sudo systemctl disable --now $service
done

# Turn off swap
sudo dphys-swapfile swapoff
sudo systemctl disable dphys-swapfile

# Disable systemd logging
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nStorage=none\nRuntimeMaxUse=0" | sudo tee /etc/systemd/journald.conf.d/00-no-logging.conf > /dev/null
sudo systemctl restart systemd-journald

# Optional: disable WiFi (uncomment if not used)
 sudo ifconfig wlan0 down

# Switch to minimal runlevel
sudo systemctl isolate multi-user.target

echo " Silent Benchmark Mode active. Ready for precise measurement."
