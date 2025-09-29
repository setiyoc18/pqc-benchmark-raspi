#!/bin/bash

echo " Restoring Benchmark Environment..."

# Re-enable essential services
for service in triggerhappy avahi-daemon bluetooth hciuart cups cron rsyslog; do
  sudo systemctl enable --now $service
done

# Re-enable swap
sudo systemctl enable dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Restore logging
sudo rm -f /etc/systemd/journald.conf.d/00-no-logging.conf
sudo systemctl restart systemd-journald

# Optional: re-enable WiFi (if it was disabled)
 sudo ifconfig wlan0 up

# Return to default graphical/console target
sudo systemctl isolate default.target

echo " Environment restored to normal mode."
