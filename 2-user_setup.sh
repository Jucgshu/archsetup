#!/usr/bin/env bash
# ------------------------------------------------------------------------

aur=(gnome-browser-connector oh-my-zsh-git ttf-meslo-nerd-font-powerlevel10k jellyfin-media-player)

# ------------------------------------------------------------------------

installYay () {
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  cd /tmp/yay-bin
  makepkg -si
}

# ------------------------------------------------------------------------

installYayPackages () {
  for package in "${aur[@]}"; do
    yay -S $package
  done
}

# ------------------------------------------------------------------------

setGnomeSettings () {

  echo "Applying GNOME & Firefox settings, installing Yay and initializing chezmoi"

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

setAppsSettings () {

  echo "Apply other applications settings"

  # Start with a clean Firefox profile
  firefox -CreateProfile $USER
  cp ./firefox/prefs.js ~/.mozilla/firefox/*.$USER
  cp ./firefox/search.json.mozlz4 ~/.mozilla/firefox/*.$USER

  # Copy dotfiles to ~/home
  chezmoi init https://github.com/Jucgshu/dotfiles
  chezmoi update -v

  # Add UOSC to Mpv
  wget -NP ~/.config/mpv/scripts https://github.com/tomasklaen/uosc/releases/latest/download/uosc.lua
  wget -NP ~/.config/mpv/script-opts https://github.com/tomasklaen/uosc/releases/latest/download/uosc.conf
}

# ------------------------------------------------------------------------

enableOtherServices () {
  echo "Enable other services"
  systemctl --user start syncthing.service
}

# ------------------------------------------------------------------------

setNetworkSettings () {

  echo "Disable IPv6 & Switching DNS to Unbound"
  nmcli connection modify $(iwgetid -r) connection.mdns yes
  nmcli connection modify $(iwgetid -r) ipv6.method "disabled"
  nmcli connection modify $(iwgetid -r) ipv4.ignore-auto-dns yes
  nmcli connection modify $(iwgetid -r) ipv4.dns "127.0.0.1"
  nmcli connection up $(iwgetid -r)
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

installYay
installYayPackages
setGnomeSettings
setAppsSettings
enableOtherServices
setNetworkSettings
finalize
