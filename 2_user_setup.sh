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

# Install Yay
cd ~/ && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && cd ~/Archinstall &&
echo "Yay OK"

# Installig extra fonts
yay ttf-meslo-nerd-font-powerlevel10k &&

# Apply GDM settings
sudo sed -i "/WaylandEnable/aAutomaticLogin=$USER" /etc/gdm/custom.conf &&
echo "GDM OK"

# Apply various GNOME settings
gsettings set org.gnome.shell.app-switcher current-workspace-only true &&
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2680 &&
gsettings set org.gnome.desktop.interface clock-show-date true &&
gsettings set org.gnome.desktop.interface clock-show-weekday true &&
gsettings set org.gnome.desktop.calendar show-weekdate true &&
gsettings set org.gnome.desktop.search-providers disabled ['org.gnome.Boxes.desktop', 'org.gnome.Characters.desktop', 'org.gnome.Software.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Epiphany.desktop'] &&
# Apply trackpad settings
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none' &&
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true &&
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false &&
gsettings set org.gnome.desktop.peripherals.touchpad middle-click-emulation false &&
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false &&
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true &&
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true &&
# Apply wallpapers
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/adwaita-l.jpg' &&
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/gnome/adwaita-d.jpg' &&
# Apply icon theme & settings
gsettings set org.gnome.desktop.background show-desktop-icons false &&
gsettings set org.gnome.desktop.interface icon-theme Papirus &&
gsettings get org.gnome.shell favorite-apps     
['firefox.desktop', 'thunderbird.desktop', 'telegramdesktop.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Calendar.desktop', 'io.github.TransmissionRemoteGtk.desktop'] &&
# Apply fonts settings
gsettings set org.gnome.desktop.interface font-name "Nimbus Sans Regular 12" &&
gsettings set org.gnome.desktop.interface document-font-name "Nimbus Sans Regular 12" &&
gsettings set org.gnome.desktop.interface monospace-font-name "MesloLGS NF 12" &&
gsettings set org.gnome.desktop.interface font-hinting 'medium' &&
# Apply energy settings
powerprofilesctl set power-saver &&
gsettings set org.gnome.desktop.interface show-battery-percentage true &&
# Apply privacy settings
org.gnome.desktop.privacy disable-microphone true &&
org.gnome.desktop.privacy disable-camera true &&
# Set audio output to 0%
pactl set-sink-mute @DEFAULT_SINK@ toggle &&
pactl set-source-mute @DEFAULT_SOURCE@ toggle &&
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
