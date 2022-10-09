#!/usr/bin/env bash
# ------------------------------------------------------------------------

pkg=(acpi audacity awesome-terminal-fonts calibre element-desktop firefox firefox-i18n-fr gimp keepassxc libva-utils mediaelch mpv musescore papirus-icon-theme profile-cleaner simple-scan syncthing telegram-desktop thunderbird thunderbird-i18n-fr transmission-remote-gtk ttf-font-awesome ttf-roboto wol)
aur=(gnome-browser-connector oh-my-zsh-git ttf-meslo-nerd-font-powerlevel10k jellyfin-media-player)

# ------------------------------------------------------------------------

installPacmanPackages () {
  for package in "${pkg[@]}"; do
    pacman -S "$package" --noconfirm >/dev/null 2>&1
  done
  echo "Install Pacman packages: OK"
}

# ------------------------------------------------------------------------

installYay () {

  # Main function
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin >/dev/null 2>&1
  cd /tmp/yay-bin
  makepkg -si

  # Check function
  if $(pacman -Qi yay &>/dev/null); then
    echo "Install Yay: OK"
  else
    echo "Install Yay: Error"
  fi
}

# ------------------------------------------------------------------------

installYayPackages () {
  for package in "${aur[@]}"; do
    yay -S "$package" --noeditmenu --noconfirm --removemake --cleanafter >/dev/null 2>&1
  done
  echo "Install AUR packages: OK"
}

# ------------------------------------------------------------------------

setChezMoi () {
  read -p "Enter your Github username" github
  chezmoi init https://github.com/$github/dotfiles >/dev/null 2>&1
  chezmoi update >/dev/null 2>&1
}

# ------------------------------------------------------------------------

setGnomeSettings () {

  # Apply Nautilus settings
  gsettings set org.gtk.Settings.FileChooser sort-directories-first true

  # Apply night light settings
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2680

  # Apply date settings
  gsettings set org.gnome.desktop.interface clock-show-date true
  gsettings set org.gnome.desktop.interface clock-show-weekday true
  gsettings set org.gnome.desktop.calendar show-weekdate true

  # Apply trackpad settings
  gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none'
  gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
  gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
  gsettings set org.gnome.desktop.peripherals.touchpad middle-click-emulation false
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true

  # Apply wallpapers
  gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/adwaita-l.jpg'
  gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/gnome/adwaita-d.jpg'

  # Apply icon theme & settings
  gsettings set org.gnome.desktop.background show-desktop-icons false
  gsettings set org.gnome.desktop.interface enable-hot-corners false
  gsettings set org.gnome.desktop.interface icon-theme Papirus
  gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'thunderbird.desktop', 'telegramdesktop.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Calendar.desktop', 'io.github.TransmissionRemoteGtk.desktop']"

  # Apply fonts settings
  gsettings set org.gnome.desktop.interface font-name "Nimbus Sans Regular 12"
  gsettings set org.gnome.desktop.interface document-font-name "Nimbus Sans Regular 12"
  gsettings set org.gnome.desktop.interface monospace-font-name "MesloLGS NF 12"
  gsettings set org.gnome.desktop.interface font-hinting "medium"

  # Apply energy settings
  powerprofilesctl set power-saver
  gsettings set org.gnome.desktop.interface show-battery-percentage true

  # Apply privacy settings
  gsettings set org.gnome.desktop.privacy disable-microphone true
  gsettings set org.gnome.desktop.privacy disable-camera true

  # Set audio output to 0%
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  pactl set-source-mute @DEFAULT_SOURCE@ toggle

  # Apply various GNOME settings
  gsettings set org.gnome.shell.app-switcher current-workspace-only true
  gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Boxes.desktop', 'org.gnome.Characters.desktop', 'org.gnome.Software.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Epiphany.desktop']"
}

# ------------------------------------------------------------------------

setGnomeExtensions () {

  # Install ddterm
  wget -NP /tmp/ddterm https://github.com/ddterm/gnome-shell-extension-ddterm/releases/latest/download/ddterm@amezin.github.com.shell-extension.zip >/dev/null 2>&1
  gnome-extensions install -f /tmp/ddterm/ddterm@amezin.github.com.shell-extension.zip >/dev/null 2>&1
  gnome-extensions enable ddterm@amezin.github.com >/dev/null 2>&1
  cp -rf ./gnome/com.github.amezin.ddterm.gschema.xml ~/.local/share/gnome-shell/extensions/ddterm@amezin.github.com/schemas

  # Install Arch-update
  wget -NP /tmp/arch-update https://github.com/RaphaelRochet/arch-update/releases/latest/download/arch-update@RaphaelRochet.zip >/dev/null 2>&1
  gnome-extensions install -f /tmp/arch-update/arch-update@RaphaelRochet.zip >/dev/null 2>&1
  gnome-extensions enable arch-update@RaphaelRochet >/dev/null 2>&1
  cp -rf ./gnome/org.gnome.shell.extensions.arch-update.gschema.xml ~/.local/share/gnome-shell/extensions/arch-update@RaphaelRochet/schemas
}

# ------------------------------------------------------------------------

setAppsSettings () {

  # Create Firefox profile from scratch
  firefox -CreateProfile "$USER"
  
  # Copy Firefox prefs.js, generated with https://ffprofile.com/
  cp ./firefox/prefs.js ~/.mozilla/firefox/*.$USER
  
  # Move Firefox cache to RAM
  sed -i "s/<id>/$(id -u)/g" prefs.js
  cp ./firefox/search.json.mozlz4 ~/.mozilla/firefox/*.$USER

  # Copy Mpv config files
  mkdir ~/.config/mpv
  cp ./archlinux/mpv/* ~/.config/mpv/

  # Download and configure UOSC
  wget -NP ~/.config/mpv/script-opts https://github.com/tomasklaen/uosc/releases/latest/download/uosc.conf >/dev/null 2>&1
  wget -NP /tmp/uosc https://github.com/tomasklaen/uosc/releases/latest/download/uosc.zip >/dev/null 2>&1
  cd /tmp/uosc || exit
  unzip uosc.zip >/dev/null 2>&1
  rm uosc.zip
  cp -Rf /tmp/uosc/* ~/.config/mpv/
  # Tweak UOSC config a bit
  sed -i -e 's|[# ]*timeline_style[ ]*=[ ]*.*|timeline_style=line|g' ~/.config/mpv/script-opts/uosc.conf
  sed -i -e 's|[# ]*timeline_size_max_fullscreen[ ]*=[ ]*.*|timeline_size_max_fullscreen=40|g' ~/.config/mpv/script-opts/uosc.conf
  sed -i -e 's|[# ]*volume_size_fullscreen[ ]*=[ ]*.*|volume_size_fullscreen=40|g' ~/.config/mpv/script-opts/uosc.conf
}

# ------------------------------------------------------------------------

enableOtherServices () {
  systemctl --user start syncthing.service
}

# ------------------------------------------------------------------------

setNetworkSettings () {

  echo "Enable mDNS, disable IPv6 & Switching DNS to Unbound"
  
  nmcli -g name,type connection  show  --active | awk -F: '/ethernet|wireless/ { print $1 }' | while read connection
  do
    nmcli connection modify "$connection" connection.mdns yes
    nmcli connection modify "$connection" ipv6.method "disabled"
    nmcli connection modify "$connection" ipv4.ignore-auto-dns yes
    nmcli connection modify "$connection" ipv4.dns "127.0.0.1"
    nmcli connection up "$connection"
  done
}

# ------------------------------------------------------------------------

finalize () {
  echo "Archlinux has been configured"
  echo ""
  echo "You can also install GNOME extensions like:"
  echo " - ddterm: https://extensions.gnome.org/extension/3780/ddterm/"
  echo " - Night Theme Switcher: https://extensions.gnome.org/extension/2236/night-theme-switcher/"
  echo " - Archlinux Updates Indicator: https://extensions.gnome.org/extension/1010/archlinux-updates-indicator/"
}

# ------------------------------------------------------------------------

installPacmanPackages
installYay
installYayPackages
setChezMoi
setGnomeSettings
setGnomeExtensions
setAppsSettings
enableOtherServices
setNetworkSettings
finalize