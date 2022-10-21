#!/usr/bin/env bash
# ------------------------------------------------------------------------

getVariables () {
  
  # Get chassis
    select CHASSIS in "Laptop" "Desktop" "Server"; do
    case $CHASSIS in
      Laptop ) hostnamectl chassis laptop; break;;
      Desktop ) hostnamectl chassis desktop; break;;
      Server ) hostnamectl chassis server; break;;
    esac
  done
  
}

# ------------------------------------------------------------------------

createUser () {
  
  # Main Function
  systemctl enable --now systemd-homed.service >/dev/null 2>&1
  read -p "User you wish to create: " MYUSER
  if [ "$(blkid -o value -s TYPE "$(df --output=source / | tail -n +2)")" == btrfs ];  then
    homectl create "$MYUSER" --shell=/usr/bin/zsh --member-of=wheel --storage=subvolume >/dev/null 2>&1
  elif [ "$(blkid -o value -s TYPE "$(df --output=source / | tail -n +2)")" == f2fs ]; then
    homectl create "$MYUSER" --shell=/usr/bin/zsh --member-of=wheel --storage=directory >/dev/null 2>&1
  fi
  sed -i "/WaylandEnable/AutomaticLogin=$MYUSER" /etc/gdm/custom.conf >/dev/null 2>&1

  # Check function
  if id "$MYUSER" &>/dev/null; then
    echo "Create user: $(tput setaf 2)OK"
  else
    echo "Create user: $(tput setaf 1)Error"
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
    echo "Enable Unbound: $(tput setaf 2)OK"
  else
    echo "Enable Unbound: $(tput setaf 1)Error"
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
    echo "Enable Reflector: $(tput setaf 2)OK"
  else
    echo "Enable Reflector: $(tput setaf 1)Error"
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
  echo "blacklist psmouse" > /etc/modprobe.d/modprobe.conf
  cp ./archlinux/mkinitcpio.conf /etc/mkinitcpio.conf
  mkinitcpio -p linux >/dev/null 2>&1

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
    echo "Hardware settings: $(tput setaf 2)OK"
  else
    echo "Hardware settings: $(tput setaf 1)Error"
  fi
}

# ------------------------------------------------------------------------

setNetworkSettings () {

  # Main Function

  #--- Enable Firewalld
  if [ "$(hostnamectl chassis)" == laptop ] ; then
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
    echo "Set network settings: $(tput setaf 2)OK"
  else
    echo "Set network settings: $(tput setaf 1)Error"
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

  if [ "$(hostnamectl chassis)" == laptop ] ; then
    #--- Enable Firefox Wayland
    echo "MOZ_ENABLE_WAYLAND=1 firefox" >> /etc/environment

    #--- Allow user to access a mounted fuse
    sed -i -e 's|[# ]*user_allow_other|user_allow_other|g' /etc/fuse.conf

    #--- Copy wallpapers
    cp ./img/adwaita*.jpg /usr/share/backgrounds/gnome/
  fi

  # Check Function
  if grep -q "#Color" /etc/pacman.conf && grep -q "#ParallelDownloads" /etc/pacman.conf; then
    echo "User settings: $(tput setaf 1)Error"
  else
    echo "User settings: $(tput setaf 2)OK"
  fi
  }

# ------------------------------------------------------------------------

getVariables
createUser
enableUnbound
enableReflector
setNetworkSettings
setHardwareSettings
setUserSettings