#!/usr/bin/env bash
# ------------------------------------------------------------------------

echo
echo "Applying network settings"
echo

# Enable Firewalld
sudo systemctl enable --now firewalld.service &&
sudo firewall-cmd --zone=home --change-interface=wlan0 &&
echo "Firewalld OK"

# Enable mDNS
nmcli connection modify $(iwgetid -r) connection.mdns yes &&
echo "mDNS OK"

# Enable services
sudo systemctl enable --now systemd-resolved.service && echo "Systemd-resolved OK"
sudo systemctl restart NetworkManager.service &&
echo "Network has been configured"

# ------------------------------------------------------------------------

echo
echo "Applying GNOME & Firefox settings, installing Yay and initializing chezmoi"
echo

# Apply GDM settings
sudo sed -i "/WaylandEnable/aAutomaticLogin=$USER" /etc/gdm/custom.conf &&
echo "GDM OK"

# Apply various GNOME settings
gsettings set org.gnome.shell.app-switcher current-workspace-only true &&
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2680 &&
gsettings set org.gnome.desktop.interface clock-show-date true &&
gsettings set org.gnome.desktop.calendar show-weekdate true &&
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none' &&
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true &&
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false &&
gsettings set org.gnome.desktop.peripherals.touchpad middle-click-emulation false &&
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false &&
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true &&
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true &&
gsettings set org.gnome.desktop.interface icon-theme Papirus &&
# Apply GNOME Energy settings
powerprofilesctl set power-saver &&
gsettings set org.gnome.desktop.interface show-battery-percentage true

echo "Gnome OK"

# Start with a clean Firefox profile
firefox -CreateProfile $USER &&
cp ./Firefox/prefs.js ~/.mozilla/firefox/*.$USER &&
cp ./Firefox/search.json.mozlz4 ~/.mozilla/firefox/*.$USER &&
echo "Firefox OK"

# Copy dotfiles to ~/home
read -p "Enter the name of your Github user: " github
chezmoi init https://github.com/$github/dotfiles.git &&
echo "Chezmoi OK"

# Add UOSC to Mpv
wget -NP ~/.config/mpv/scripts https://github.com/tomasklaen/uosc/releases/latest/download/uosc.lua &&
wget -NP ~/.config/mpv/script-opts https://github.com/tomasklaen/uosc/releases/latest/download/uosc.conf
echo "Mpv OK"

# Install Yay
cd ~/ && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si &&
echo "Yay OK" &&
echo "All applications have been configured"

# ------------------------------------------------------------------------

echo
echo "Enable other services"
echo

sudo systemctl enable --now rngd.service && echo "Rngd OK"
systemctl --user start syncthing.service && echo "Syncthing OK" &&
echo "All services have been enabled"

# ------------------------------------------------------------------------

echo "Done!"
echo
echo "Reboot now..."
echo
