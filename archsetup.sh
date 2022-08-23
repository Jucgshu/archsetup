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

echo "Done!"
echo
echo "Reboot now..."
echo
