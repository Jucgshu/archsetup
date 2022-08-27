#!/usr/bin/env bash
# ------------------------------------------------------------------------

echo
echo "Applying network settings"
echo

# Enable Unbound
sudo mv ./Archlinux/etc/unbound/unbound.conf /etc/unbound/  &&
sudo mv ./Archlinux/etc/systemd/system/roothints.service /etc/systemd/system/ &&
sudo mv ./Archlinux/etc/systemd/system/roothints.timer /etc/systemd/system/ &&
sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache &&
sudo systemctl enable --now roothints.timer &&
sudo systemctl enable --now unbound.service &&
echo "Unbound OK"

# Enable Reflector
sudo sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf &&
sudo sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf &&
sudo sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf &&
sudo systemctl start reflector.service &&
echo "Reflector OK"

# Enable mDNS
read -p "Enter the SSID you wish to connect to: " wifi
nmcli connection modify $wifi connection.mdns yes &&
echo "mDNS OK"

# Enable services
sudo systemctl enable --now systemd-resolved.service && echo "Systemd-resolved OK"
sudo systemctl restart NetworkManager.service &&
echo "Network has been configured"

# ------------------------------------------------------------------------

echo
echo "Applying hardware settings"
echo

# Add Trim option to SSD
sudo sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab &&
echo "Fstab OK"

# Add power savings options to boot
sudo sed -i 's/$/ i915.enable_rc6=1 i915.enable_psr=2/' /boot/loader/entries/*linux.conf &&
echo "Boot options OK"

# Enable CPUPower
sudo systemctl enable --now cpupower.service &&
echo "CPUPower OK"

# Enable Powertop
sudo mv ./Archlinux/etc/systemd/system/powertop.service /etc/systemd/system/ &&
sudo systemctl enable --now powertop.service &&
echo "Powertop OK"

# Fix buggy lid buggy firmware by delegating lid close event to Systemd
sudo sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf &&
sudo sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf &&
echo "Lid OK" &&
echo "All hardware settings have been configured"

# ------------------------------------------------------------------------

echo
echo "Applying Pacman, GNOME & Firefox settings, installing Yay and initializing chezmoi"
echo

# Apply Pacman Settings
sudo sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf &&
sudo sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf &&
echo "Pacman OK"

# Apply GDM settings
read -p "Enter the name of your Archlinux user" user
sudo sed -i '/WaylandEnable/aAutomaticLogin=$user' /etc/gdm/custom.conf &&
echo "GDM OK"

# Apply various GNOME settings
gsettings set org.gnome.shell.app-switcher current-workspace-only true &&
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2680 &&
gsettings set org.gnome.desktop.interface clock-show-date true &&
gsettings set org.gnome.desktop.calendar show-weekdate true &&
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none' &&
gsettings set org.gnome.desktop.interface icon-theme Papirus &&
echo "Gnome OK"

# Start with a clean Firefox profile
firefox -CreateProfile $user &&
cp ./Firefox/prefs.js ~/.mozilla/firefox/*.$firefox &&
cp ./Firefox/search.json.mozlz4 ~/.mozilla/firefox/*.$firefox &&
echo "Firefox OK"

# Copy dotfiles to ~/home
read -p "Enter the name of your Github user: " github
chezmoi init https://github.com/$github/dotfiles.git &&
echo "Chezmoi OK"

# Install Yay
cd ~/ && git clone https://aur.archlinux.org/yay.git && cd yay &&
echo "Yay OK" &&
echo "All applications have been configured"

# ------------------------------------------------------------------------

echo
echo "Enable other services"
echo

sudo systemctl enable --now rngd.service && echo "Rngd OK"
sudo systemctl enable --now firewalld.service && echo "Firewalld OK"
systemctl --user start syncthing.service && echo "Syncthing OK" &&
echo "All services have been enabled"

# ------------------------------------------------------------------------

echo "Done!"
echo
echo "Reboot now..."
echo
