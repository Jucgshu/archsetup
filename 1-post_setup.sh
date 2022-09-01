#!/usr/bin/env bash
# ------------------------------------------------------------------------

createUser () {
  echo "Enable Reflector"
  systemctl enable --now systemd-homed.service
  read -p "User you wish to create" MYUSER
  homectl create $MYUSER --shell=/usr/bin/zsh --member-of=wheel --storage=subvolume
  sed -i "/WaylandEnable/aAutomaticLogin=$MYUSER" /etc/gdm/custom.conf
}

createUser
