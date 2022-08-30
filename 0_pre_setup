#!/usr/bin/env bash
# ------------------------------------------------------------------------

# Connect to the network
read -p "Enter the name of your SSID: " SSID
read -p "Enter passphrase: " PASSPHRASE
iwctl --$PASSPHRASE station wlan0 connect $SSID &&
echo "Wifi connected"

# Enable Reflector
sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf &&
sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf &&
sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf &&
echo "Reflector OK"

# Apply Pacman Settings
sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf &&
sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf &&
pacman -Syy &&
echo "Pacman OK"

# Install Arch install tools
pacman -S --noconfirm git &&
git clone https://github.com/Jucgshu/archinstall &&
echo "Arch install tools installed"

# Start Archinstall script
archinstall --config archinstall/user_configuration.json
