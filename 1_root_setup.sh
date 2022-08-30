#!/usr/bin/env bash
# ------------------------------------------------------------------------

echo
echo "Applying network settings"
echo

# Enable Unbound
cp ./Archlinux/etc/unbound/unbound.conf /etc/unbound/  &&
cp ./Archlinux/etc/systemd/system/roothints.service /etc/systemd/system/ &&
cp ./Archlinux/etc/systemd/system/roothints.timer /etc/systemd/system/ &&
curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache &&
systemctl enable --now roothints.timer &&
systemctl enable --now unbound.service &&
echo "Unbound OK"

# Enable Reflector
sed -i -e 's|[# ]*--country[ ]* [ ]*.*|--country France,Germany|g' /etc/xdg/reflector/reflector.conf &&
sed -i -e 's|[# ]*--protocol[ ]* [ ]*.*|--protocol https|g' /etc/xdg/reflector/reflector.conf &&
sed -i -e 's|[# ]*--latest[ ]* [ ]*.*|--latest 5|g' /etc/xdg/reflector/reflector.conf &&
systemctl start reflector.service &&
echo "Reflector OK"

# ------------------------------------------------------------------------

echo
echo "Applying hardware settings"
echo

# Add Trim option to SSD
sed -i 's/ssd,/ssd,discard=async,/g' /etc/fstab &&
echo "Fstab OK"

# Add power savings options to boot
sed -i '$s/$/i915.enable_rc6=1 i915.enable_psr=2/' /boot/loader/entries/*linux.conf &&
echo "Boot options OK"

# Copy Mkinitcpio file
cp ./Archlinux/etc/mkinitcpio.conf /etc/mkinitcpio.conf &&
mkinitcpio -p linux &&
echo "Mkinitcpio OK"

# Enable CPUPower
systemctl enable --now cpupower.service &&
echo "CPUPower OK"

# Enable Powertop
mv ./Archlinux/etc/systemd/system/powertop.service /etc/systemd/system/ &&
systemctl enable --now powertop.service &&
echo "Powertop OK"

# Fix buggy lid buggy firmware by delegating lid close event to Systemd
sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf &&
sed -i -e 's|[# ]*IgnoreLid[ ]*=[ ]*.*|IgnoreLid=true|g' /etc/UPower/UPower.conf &&
echo "Lid OK" &&
echo "All hardware settings have been configured"

# ------------------------------------------------------------------------

echo
echo "Applying Pacman settings"
echo

# Apply Pacman Settings
sed -i -e 's|[# ]*Color.*|Color|g' /etc/pacman.conf &&
sed -i -e 's|[# ]*ParallelDownloads[ ]* = [ ]*.*|ParallelDownloads = 5|g' /etc/pacman.conf &&
echo "Pacman OK"

# Add members of wheel to /etc/sudoers
echo "%wheel ALL=(ALL:ALL) ALL" | (EDITOR="tee -a" visudo)
echo "Wheel members have been granted with superpowers"
