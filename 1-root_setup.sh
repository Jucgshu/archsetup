#!/usr/bin/env bash
# ------------------------------------------------------------------------

createUser () {
  echo "Enable Reflector"
  systemctl enable --now systemd-homed.service
  read -p "User you wish to create" MYUSER
  homectl create $MYUSER --shell=/usr/bin/zsh --member-of=wheel --storage=subvolume
  sed -i "/WaylandEnable/aAutomaticLogin=$MYUSER" /etc/gdm/custom.conf
}

# ------------------------------------------------------------------------

enableUnbound () {
  echo "Enable Unbound"
  cp ./archlinux/unbound.conf /etc/unbound/
  cp ./archlinux/roothints.service /etc/systemd/system/
  cp ./archlinux/roothints.timer /etc/systemd/system/
  curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache
  systemctl enable --now roothints.timer
  systemctl enable --now unbound.service
}

# ------------------------------------------------------------------------

enableReflector () {
  echo "Enable Reflector"
  sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf
  sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf
  sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf
  systemctl start reflector.service
}

# ------------------------------------------------------------------------

setNetworkSettings () {

  echo "Applying network settings"

  # Enable Firewalld
  systemctl enable --now firewalld.service
  firewall-cmd --zone=home --change-interface=wlan0 --permanent

  # Enable services
  systemctl enable --now systemd-resolved.service
}

# ------------------------------------------------------------------------

setHardwareSettings () {
  
  echo "Applying hardware settings"

  # Add Trim option to SSD
  sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab

  # Add power savings options to boot
  sed -i '$s/$/i915.enable_rc6=1 i915.enable_psr=2/' /boot/loader/entries/*linux.conf

  # Copy Mkinitcpio file
  echo "blacklist psmouse" > /etc/modprobe.d/modprobe.conf
  cp ./archlinux/mkinitcpio.conf /etc/mkinitcpio.conf
  mkinitcpio -p linux

  # Enable CPUPower
  systemctl enable --now cpupower.service

  # Enable Powertop
  cp ./archlinux/powertop.service /etc/systemd/system/
  systemctl enable --now powertop.service

  # Fix buggy lid buggy firmware by delegating lid close event to Systemd
  sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf
  sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf
  
  # Enable RNG daemon
  systemctl enable --now rngd.service
}

# ------------------------------------------------------------------------

setUserSettings () {

  echo "Applying user settings"

  # Apply Pacman Settings
  sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf
  sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf
  cp ./archlinux/pacman-cache-cleanup.hook /usr/share/libalpm/hooks/

  # Add members of wheel to /etc/sudoers
  echo "%wheel ALL=(ALL:ALL) ALL" | (EDITOR="tee -a" visudo)
  echo "Wheel members have been granted with superpowers"

  # Enable Firefox Wayland
  echo "MOZ_ENABLE_WAYLAND=1 firefox" >> /etc/environment

  # Copy wallpapers
  cp ./img/adwaita*.jpg /usr/share/backgrounds/gnome/
  }

# ------------------------------------------------------------------------

createUser
enableUnbound
enableReflector
setNetworkSettings
setHardwareSettings
setUserSettings
