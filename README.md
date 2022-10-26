<!-- <div align="center"> -->
<img src="https://github.com/archlinux/archinstall/raw/master/docs/logo.png" alt="drawing" width="200"/>

<!-- </div> -->
# Archsetup post-installer tools

Archsetup consists in files and scripts to ease the Arch post-installation process. A fresh Archlinux system must be installed first. The new [Archinstall](https://github.com/archlinux/archinstall) script can speed up the process. *(**Note**: the script must be run from an Archlinux live ISO booted into EFI mode)*. The [user_packages file](https://github.com/Jucgshu/archinstall/blob/main/user_packages) can be used to copy the packages needed for the base installation. This repo consists in 3 main scripts. The first one is optional `0-pre_setup.sh`, and might become useless eventually.

Once the repo has been cloned or copied , you can start the Archlinux installation process by running:

    $ archinstall --config ./archsetup/user_configuration.json

**Note:** On standard Archlinux installations, Json files are stored in `/var/log/archinstall/`

# Usage
1. After installing Archlinux, connect as root and execute the 1st script. It will create the main admin user, enable various services and tweak the system to my likings (by enabling hardware acceleration for example):

    `# ./1-root_setup.sh`

1. Once the first script has finished its job, you can log into Gnome and run the second script from the GUI (as normal user). It will install Yay and AUR packages defined in the array, tweak some settings such as Gnome settings, Firefox or connection settings (mDNS...), and initialize chezmoi for managing dotfiles:

    `# .2-user_setup.sh`

See Archlinux wiki for details:
* [Systemd](https://wiki.archlinux.org/title/Systemd)
* [Systemd-boot](https://wiki.archlinux.org/title/Systemd-boot)
* [Systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd)
* [Systemd-homed](https://wiki.archlinux.org/title/Systemd-homed)
* [Unbound](https://wiki.archlinux.org/title/Unbound)
* [Users and groups](https://wiki.archlinux.org/title/Users_and_groups)
* [Btrfs](https://wiki.archlinux.org/title/Btrfs)
* [F2FS](https://wiki.archlinux.org/title/F2FS)
* [GNOME](https://wiki.archlinux.org/title/Gnome)
* [Firefox](https://wiki.archlinux.org/title/Firefox)