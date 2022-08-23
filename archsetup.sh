#!/usr/bin/env bash
# ------------------------------------------------------------------------

echo
echo "Setting laptop lid close to suspend"

sudo sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf

# ------------------------------------------------------------------------

echo
echo "Fix lid buggy firmware"

sudo sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf

# ------------------------------------------------------------------------

echo
echo "Enable some nice Reflector options"

sudo sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf
sudo sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf
sudo sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf

# ------------------------------------------------------------------------

echo
echo "Add TRIM option to the SSD drives"

sudo sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab

# ------------------------------------------------------------------------

echo
echo "Add power savings options to boot"

sudo sed -i 's/$/ i915.enable_rc6=1 i915.enable_psr=2/' /boot/loader/entries/*linux.conf
# ------------------------------------------------------------------------

echo
echo "Apply GNOME settings"

gsettings set org.gnome.shell.app-switcher current-workspace-only true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2680
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none'
gsettings set org.gnome.desktop.interface icon-theme Papirus
# ------------------------------------------------------------------------

echo
echo "Install Yay"

cd ~/ && git clone https://aur.archlinux.org/yay.git && cd yay
# ------------------------------------------------------------------------

sudo systemctl start reflector.service
sudo systemctl enable --now rngd.service
sudo systemctl enable --now cpupower.service
sudo systemctl enable --now firewalld.service
systemctl --user start syncthing.service

echo "Done!"
echo
echo "Reboot now..."
echo
