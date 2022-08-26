#!/usr/bin/env bash
# ------------------------------------------------------------------------

echo
echo "Applying network settings"

# Enable Unbound
sudo mv ./Archlinux/etc/unbound/unbound.conf /etc/unbound/
sudo mv ./Archlinux/etc/systemd/system/roothints.service /etc/systemd/system/
sudo mv ./Archlinux/etc/systemd/system/roothints.timer /etc/systemd/system/
sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache
sudo systemctl enable --now roothints.timer
sudo systemctl enable --now unbound.service

# Enable Reflector
sudo sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf
sudo sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf
sudo sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf
sudo systemctl start reflector.service

# Enable mDNS
read -p "Enter the SSID you wish to connect to: " wifi
nmcli connection modify $wifi connection.mdns yes

# Enable services
sudo systemctl enable --now systemd-resolved.service
sudo systemctl restart NetworkManager.service

# ------------------------------------------------------------------------

echo
echo "Applying hardware settings"

# Add Trim option to SSD
sudo sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab

# Add power savings options to boot
sudo sed -i 's/$/ i915.enable_rc6=1 i915.enable_psr=2/' /boot/loader/entries/*linux.conf

# Enable CPUPower
sudo systemctl enable --now cpupower.service

# Enable Powertop
sudo mv ./Archlinux/etc/systemd/system/powertop.service /etc/systemd/system/
sudo systemctl enable --now powertop.service

# Fix buggy lid buggy firmware by delegating lid close event to Systemd
sudo sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf
sudo sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf

# ------------------------------------------------------------------------

echo "Applying Pacman, GNOME & Firefox settings, installing Yay and initializing chezmoi"

# Apply Pacman Settings
sudo sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf
sudo sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf

# Apply various GNOME settings
gsettings set org.gnome.shell.app-switcher current-workspace-only true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2680
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none'
gsettings set org.gnome.desktop.interface icon-theme Papirus

# Start with a clean Firefox profile
read -p "Enter the name of the Firefox profile you wish to create: " firefox
firefox -CreateProfile $firefox
cp ./Firefox/prefs.js ~/.mozilla/firefox/*.$firefox

# Copy dotfiles to ~/home
read -p "Enter the name of your Github user: " github
chezmoi init https://github.com/$github/dotfiles.git

# Install Yay
cd ~/ && git clone https://aur.archlinux.org/yay.git && cd yay

# ------------------------------------------------------------------------

echo
echo "Enable other services"

sudo systemctl enable --now rngd.service
sudo systemctl enable --now firewalld.service
systemctl --user start syncthing.service

# ------------------------------------------------------------------------

echo "Done!"
echo
echo "Reboot now..."
echo
