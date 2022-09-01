#!/usr/bin/env bash
# ------------------------------------------------------------------------

enableReflector () {
  echo "Enable Reflector"
  sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf
  sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf
  sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf
}

setPacmanSettings () {
  echo "Apply Pacman Settings"
  sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf
  sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf
  pacman -Syy
}

setScriptsSettings () {
  chmod +x 1-post_setup.sh
}

startArchinstallScript () {
  archinstall --config archinstall/user_configuration.json
}

enableReflector
setPacmanSettings
setScriptsSettings
startArchinstallScript
