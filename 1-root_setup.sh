#!/usr/bin/env bash
# ------------------------------------------------------------------------

createUser () {
  
  echo "Create main user"
  systemctl enable --now systemd-homed.service >/dev/null 2>&1
  read -p "User you wish to create: " MYUSER
  if [ "$(blkid -o value -s TYPE /dev/nvme0n1p2)" == btrfs ];  then
    homectl create "$MYUSER" --shell=/usr/bin/zsh --member-of=wheel --storage=subvolume >/dev/null 2>&1
  elif [ "$(blkid -o value -s TYPE /dev/nvme0n1p2)" == f2fs ]; then
    homectl create "$MYUSER" --shell=/usr/bin/zsh --member-of=wheel >/dev/null 2>&1
  fi
  sed -i "/WaylandEnable/AutomaticLogin=$MYUSER" /etc/gdm/custom.conf >/dev/null 2>&1

}

# ------------------------------------------------------------------------

enableUnbound () {
  echo "Enable Unbound"
  cp ./archlinux/unbound.conf /etc/unbound/
  cp ./archlinux/roothints.service /etc/systemd/system/
  cp ./archlinux/roothints.timer /etc/systemd/system/
  curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache >/dev/null 2>&1
  systemctl enable --now roothints.timer >/dev/null 2>&1
  systemctl enable --now unbound.service >/dev/null 2>&1

  # Check function
  if [[ -f /etc/unbound/unbound.conf && -f /etc/systemd/system/roothints.service && -f /etc/systemd/system/roothints.timer ]] && systemctl is-active --quiet unbound.service && systemctl is-active --quiet roothints.timer; then
    echo "Create user: OK"
  else
    echo "Create user: Error"
  fi
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
  
  echo "Select your computer chassis"
  select chassis in "Laptop" "Desktop" "Server"; do
    case $chassis in
      Laptop ) hostnamectl chassis laptop; break;;
      Desktop ) hostnamectl chassis desktop; break;;
      Server ) hostnamectl chassis server; break;;
    esac
  done

  echo "Applying hardware settings"

  # Add Trim option to SSD
  if [ "$(blkid -o value -s TYPE /dev/nvme0n1p2)" == btrfs ];  then
    sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab
  elif [ "$(blkid -o value -s TYPE /dev/nvme0n1p2)" == f2fs ]; then
    sed -i 's/ssd,/ssd,nodiscard,/g' /etc/fstab
  fi

  # Add power savings options to boot
  if eval "$(pacman -Qi grub &>/dev/null)"; then
    echo ""
  else
    sed -i '$s/$/i915.enable_psr=2/' /boot/loader/entries/*linux.conf
    echo "timeout 0" >> /boot/loader/loader.conf
  fi

  # Copy Mkinitcpio file
  echo "blacklist psmouse" > /etc/modprobe.d/modprobe.conf
  cp ./archlinux/mkinitcpio.conf /etc/mkinitcpio.conf
  mkinitcpio -p linux
  
  # Enable Systemd-Oomd
  systemctl enable --now systemd-oomd.service

  # Enable building from files in memory
  sudo sed -i -e 's|[# ]*BUILDDIR[ ]*=[ ]*.*|BUILDDIR=/tmp/makepkg|g' /etc/makepkg.conf

  # Enable RNG daemon
  systemctl enable --now rngd.service

  # Apply Laptop specific settings
  if [ "$(hostnamectl chassis)" == laptop ] ; then
    # Enable CPUPower
    systemctl enable --now cpupower.service

    # Enable Powertop
    cp ./archlinux/powertop.service /etc/systemd/system/
    systemctl enable --now powertop.service

    # Fix buggy lid buggy firmware by delegating lid close event to Systemd
    sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf
    sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf
  fi
}

# ------------------------------------------------------------------------

setUserSettings () {

  echo "Applying user settings"

  # Apply Pacman Settings
  sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf
  sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf
  cp ./archlinux/pacman-cache-cleanup.hook /usr/share/libalpm/hooks/
  cp ./archlinux/pacman-mirrorlist-cleanup.hook /usr/share/libalpm/hooks/

  # Add members of wheel to /etc/sudoers
  echo "%wheel ALL=(ALL:ALL) ALL" | (EDITOR="tee -a" visudo)
  echo "Wheel members have been granted with superpowers"

  # Enable Firefox Wayland
  echo "MOZ_ENABLE_WAYLAND=1 firefox" >> /etc/environment

  # Allow user to access a mounted fuse
  sed -i -e 's|[# ]*user_allow_other|user_allow_other|g' /etc/fuse.conf

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