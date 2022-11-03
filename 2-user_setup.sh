#!/usr/bin/env bash
# ------------------------------------------------------------------------

aur_base=(oh-my-zsh-git ttf-meslo-nerd-font-powerlevel10k)
aur_extra=(gnome-browser-connector jellyfin-media-player)

# Get script directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# ------------------------------------------------------------------------

installYay () {

  # Main function
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin >/dev/null 2>&1
  cd /tmp/yay-bin
  makepkg -si

  # Check function
  if $(pacman -Qi yay &>/dev/null); then
    echo "Yay installation: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Yay installation: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

installYayPackages () {

  # Install common AUR packages
  for package in "${aur_base[@]}"; do
    echo "Installating '$package'..."
    yay -S "$package" --noeditmenu --noconfirm --removemake --cleanafter >/dev/null 2>&1
  done

  # Install AUR packages for laptop
  if [ "$(hostnamectl chassis)" == laptop ] ; then
    for package in "${aur_extra[@]}"; do
      echo "Installating '$package'..."
      yay -S "$package" --noeditmenu --noconfirm --removemake --cleanafter >/dev/null 2>&1
    done
  fi

  # Check function
  if [ "$(hostnamectl chassis)" == laptop ] && pacman -Qi "$package" &>/dev/null; then
    echo "AUR packages installation: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "AUR packages installation: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

setChezMoi () {
  read -p "Enter your Github username: " github
  chezmoi init https://github.com/$github/dotfiles >/dev/null 2>&1
  chezmoi update >/dev/null 2>&1

  echo "Chezmoi installation: $(tput setaf 2)OK$(tput sgr 0)"
}

# ------------------------------------------------------------------------

setGnomeSettings () {

  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ] ; then

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

    echo "GNOME settings applied"

  fi
}

# ------------------------------------------------------------------------

setGnomeExtensions () {

  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ]; then

    # Install ddterm
    wget -NP /tmp/ddterm https://github.com/ddterm/gnome-shell-extension-ddterm/releases/latest/download/ddterm@amezin.github.com.shell-extension.zip >/dev/null 2>&1
    gnome-extensions install -f /tmp/ddterm/ddterm@amezin.github.com.shell-extension.zip >/dev/null 2>&1
    cp -rf "${0%/*}"/gnome/com.github.amezin.ddterm.gschema.xml ~/.local/share/gnome-shell/extensions/ddterm@amezin.github.com/schemas

    # Install Arch-update
    wget -NP /tmp/arch-update https://github.com/RaphaelRochet/arch-update/releases/latest/download/arch-update@RaphaelRochet.zip >/dev/null 2>&1
    gnome-extensions install -f /tmp/arch-update/arch-update@RaphaelRochet.zip >/dev/null 2>&1
    cp -rf "${0%/*}"/gnome/org.gnome.shell.extensions.arch-update.gschema.xml ~/.local/share/gnome-shell/extensions/arch-update@RaphaelRochet/schemas

    # Enable extensions
    sudo systemctl restart gdm.service &&
    gnome-extensions enable ddterm@amezin.github.com >/dev/null 2>&1
    gnome-extensions enable arch-update@RaphaelRochet >/dev/null 2>&1

    echo "GNOME extensions installed"

  fi
}

# ------------------------------------------------------------------------

setAppsSettings () {

  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ]; then

    # Create Firefox profile from scratch
    firefox -CreateProfile "$USER"
  
    # Copy Firefox prefs.js, generated with https://ffprofile.com/
    cp "$SCRIPT_DIR"/firefox/prefs.js ~/.mozilla/firefox/*.$USER
  
    # Move Firefox cache to RAM
    sed -i "s/<id>/$(id -u)/g" prefs.js
    cp "$SCRIPT_DIR"/firefox/search.json.mozlz4 ~/.mozilla/firefox/*.$USER

    # Copy Mpv config files
    mkdir ~/.config/mpv
    cp "$SCRIPT_DIR"/archlinux/mpv/* ~/.config/mpv/

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

    echo "Firefox, MPV & UOSC installed"

  fi
}

# ------------------------------------------------------------------------

enableOtherServices () {

  if [ "$(hostnamectl chassis)" == laptop ] ; then
    systemctl --user start syncthing.service >/dev/null 2>&1
    echo "Other services enabled"
  fi
}

# ------------------------------------------------------------------------

setNetworkSettings () {
  
  nmcli -g name,type connection  show  --active | awk -F: '/ethernet|wireless/ { print $1 }' | while read connection
  do
    nmcli connection modify "$connection" connection.mdns yes
    nmcli connection modify "$connection" ipv6.method "disabled"
    nmcli connection modify "$connection" ipv4.ignore-auto-dns yes
    nmcli connection modify "$connection" ipv4.dns "127.0.0.1"
    nmcli connection up "$connection"
  done

  echo "mDNS enabled, IPv6 disabled & Unbound set to default DNS provider"

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
setChezMoi
setGnomeSettings
setAppsSettings
enableOtherServices
setNetworkSettings
setGnomeExtensions
finalize