#!/usr/bin/env bash
# ------------------------------------------------------------------------

pacman_pkg=(acpi audacity awesome-terminal-fonts calibre element-desktop firefox firefox-i18n-fr gimp keepassxc libva-utils mediaelch mpv musescore papirus-icon-theme profile-cleaner simple-scan syncthing telegram-desktop thunderbird thunderbird-i18n-fr transmission-remote-gtk ttf-font-awesome ttf-roboto wol)

# ------------------------------------------------------------------------

getVariables () {
  
  # Get chassis
    select CHASSIS in "Laptop" "Desktop" "Server" "Virtual Machine"; do
    case $CHASSIS in
      Laptop ) hostnamectl chassis laptop; break;;
      Desktop ) hostnamectl chassis desktop; break;;
      Server ) hostnamectl chassis server; break;;
      Virtual\ Machine ) hostnamectl chassis vm; break;;
    esac
  done
  
}

# ------------------------------------------------------------------------

createUser () {
  
  # Main Function
  systemctl enable --now systemd-homed.service >/dev/null 2>&1
  read -p "User you wish to create: " MYUSER
  if [ "$(blkid -o value -s TYPE "$(df --output=source / | tail -n +2)")" == btrfs ];  then
    homectl create "$MYUSER" --shell=/usr/bin/zsh --member-of=wheel --storage=directory >/dev/null 2>&1
  elif [ "$(blkid -o value -s TYPE "$(df --output=source / | tail -n +2)")" == f2fs ]; then
    homectl create "$MYUSER" --shell=/usr/bin/zsh --member-of=wheel --storage=directory >/dev/null 2>&1
  fi
  sed -i "/WaylandEnable/AutomaticLogin=$MYUSER" /etc/gdm/custom.conf >/dev/null 2>&1

  # Check function
  if id "$MYUSER" &>/dev/null; then
    echo "Create user: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Create user: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

enableUnbound () {

  # Main Function
  cp ./archlinux/unbound.conf /etc/unbound/
  cp ./archlinux/roothints.service /etc/systemd/system/
  cp ./archlinux/roothints.timer /etc/systemd/system/
  curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache >/dev/null 2>&1
  systemctl enable --now roothints.timer >/dev/null 2>&1
  systemctl enable --now unbound.service >/dev/null 2>&1

  # Check function
  if [[ -f /etc/unbound/unbound.conf && -f /etc/systemd/system/roothints.service && -f /etc/systemd/system/roothints.timer ]] && systemctl is-active --quiet unbound.service && systemctl is-active --quiet roothints.timer; then
    echo "Enable Unbound: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Enable Unbound: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

enableReflector () {

  # Main function
  sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf
  sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf
  sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf
  systemctl start reflector.service >/dev/null 2>&1

  # Check Function
  if grep -q "country France,Germany" /etc/xdg/reflector/reflector.conf && grep -q "protocol https" /etc/xdg/reflector/reflector.conf && grep -q "latest 5" /etc/xdg/reflector/reflector.conf; then
    echo "Enable Reflector: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Enable Reflector: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

setHardwareSettings () {
  
  # Main Function

  #--- Add Trim option to SSD & install Snapper
  if [ "$(blkid -o value -s TYPE "$(df --output=source / | tail -n +2)")" == btrfs ];  then
    sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab
    pacman -S --noconfirm snapper >/dev/null 2>&1
  elif [ "$(blkid -o value -s TYPE "$(df --output=source / | tail -n +2)")" == f2fs ]; then
    sed -i 's/ssd,/ssd,nodiscard,/g' /etc/fstab
  fi

  #--- Add power savings options to boot
  if $(pacman -Qi grub &>/dev/null); then
    echo "" >/dev/null 2>&1
  else
    sed -i '$s/$/i915.enable_psr=2/' /boot/loader/entries/*linux.conf
    echo "timeout 0" >> /boot/loader/loader.conf
  fi

  #--- Copy Mkinitcpio file
  if [ "$(hostnamectl chassis)" == laptop ] ; then
    echo "blacklist psmouse" > /etc/modprobe.d/modprobe.conf
    cp ./archlinux/mkinitcpio.conf /etc/mkinitcpio.conf
    mkinitcpio -p linux >/dev/null 2>&1
  fi

  #--- Enable Systemd-Oomd
  systemctl enable --now systemd-oomd.service >/dev/null 2>&1

  #--- Enable building from files in memory
  sed -i -e 's|[# ]*BUILDDIR[ ]*=[ ]*.*|BUILDDIR=/tmp/makepkg|g' /etc/makepkg.conf

  #--- Enable RNG daemon
  systemctl enable --now rngd.service >/dev/null 2>&1
  
  #--- Apply Laptop specific settings
  if [ "$(hostnamectl chassis)" == laptop ] ; then
    #-- Enable CPUPower
    pacman -S --noconfirm cpupower power-profiles-daemon >/dev/null 2>&1
    systemctl enable --now cpupower.service >/dev/null 2>&1
    #-- Enable Powertop
    pacman -S --noconfirm powertop >/dev/null 2>&1
    cp ./archlinux/powertop.service /etc/systemd/system/
    systemctl enable --now powertop.service >/dev/null 2>&1
    #-- Fix buggy lid buggy firmware by delegating lid close event to Systemd
    sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf
    sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf
  fi

  # Check Function
  if systemctl is-active --quiet systemd-oomd.service && systemctl is-active --quiet rngd.service; then
    echo "Hardware settings: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Hardware settings: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

setNetworkSettings () {

  # Main Function

  #--- Enable Firewalld
  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ] ; then
    pacman -S --noconfirm firewalld >/dev/null 2>&1
    systemctl enable --now firewalld.service >/dev/null 2>&1
    firewall-cmd --zone=home --change-interface=wlan0 --permanent >/dev/null 2>&1
  elif [ "$(hostnamectl chassis)" == server ] ; then
    pacman -S --noconfirm ufw >/dev/null 2>&1
    systemctl enable --now ufw.service >/dev/null 2>&1
    read -p "SSH port to use: " SSHPORT
    sed -i -e "s|[# ]*Port 22.*|Port $SSHPORT|g" /etc/ssh/sshd_config
    ufw limit "$SSHPORT"
    ufw enable
  fi

  #--- Enable services
  systemctl enable --now systemd-resolved.service >/dev/null 2>&1

  # Check Function
  if (systemctl is-active --quiet firewalld.service || systemctl is-active --quiet ufw.service) && systemctl is-active --quiet systemd-resolved.service; then
    echo "Set network settings: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Set network settings: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}

# ------------------------------------------------------------------------

setUserSettings () {

  # Main Function

  #--- Apply Pacman Settings
  sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf
  sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf
  cp ./archlinux/pacman-cache-cleanup.hook /usr/share/libalpm/hooks/
  cp ./archlinux/pacman-mirrorlist-cleanup.hook /usr/share/libalpm/hooks/

  #--- Add members of wheel to /etc/sudoers
  echo "%wheel ALL=(ALL:ALL) ALL" | (EDITOR="tee -a" visudo) >/dev/null 2>&1

  #--- Apply Laptop specific settings

  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ] ; then
    #--- Enable Firefox Wayland
    echo "MOZ_ENABLE_WAYLAND=1 firefox" >> /etc/environment

    #--- Allow user to access a mounted fuse
    sed -i -e 's|[# ]*user_allow_other|user_allow_other|g' /etc/fuse.conf

    #--- Copy wallpapers
    cp ./img/adwaita*.jpg /usr/share/backgrounds/gnome/
  fi

  # Check Function
  if grep -q "#Color" /etc/pacman.conf && grep -q "#ParallelDownloads" /etc/pacman.conf; then
    echo "User settings: $(tput setaf 1)Error$(tput sgr 0)"
  else
    echo "User settings: $(tput setaf 2)OK$(tput sgr 0)"
  fi
  }

# ------------------------------------------------------------------------

installPacmanPackages () {

  # Main Function
  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ]; then
    for package in "${pacman_pkg[@]}"; do
      echo "Installating '$package'..."
      pacman -S "$package" --noconfirm >/dev/null 2>&1
    done
  fi

  # Check function
  if [ "$(hostnamectl chassis)" == laptop ] || [ "$(hostnamectl chassis)" == vm ] && pacman -Qi "$package" &>/dev/null; then
    echo "Install Pacman packages: $(tput setaf 2)OK$(tput sgr 0)"
  else
    echo "Install Pacman packages: $(tput setaf 1)Error$(tput sgr 0)"
  fi
}
# ------------------------------------------------------------------------

copyScript () {
  cp -r /root/archsetup /home/"$MYUSER"
}

getVariables
createUser
enableUnbound
enableReflector
setNetworkSettings
setHardwareSettings
setUserSettings
installPacmanPackages
copyScript