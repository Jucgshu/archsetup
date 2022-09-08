<!-- <div align="center"> -->
<img src="https://github.com/archlinux/archinstall/raw/master/docs/logo.png" alt="drawing" width="200"/>

<!-- </div> -->
# Arch installer tools

Just some files and scripts to ease the Arch installation process. Install a fresh Archlinux system first by using the new [Archinstall](https://github.com/archlinux/archinstall) script. *(**Note**: the script must be run from an Archlinux live ISO booted into EFI mode)*. The [user configuration file](https://github.com/Jucgshu/archinstall/blob/main/user_configuration.json) can be used to speed up the process. This repo consists in 3 main scripts. First one `0-pre_setup.sh` is optional, and might become useless eventually.

Once repo has been cloned or copied from repository, you can start Archlinux installation by running:

    $ archinstall --config ./archsetup/user_configuration.json

**Note:** On standard Archlinux installations, Json files are stored in `/var/log/archinstall/`

# Usage
1. After installing Archlinux, connect as root and execute 1st script. It will create the main admin user, enable various services and tweak the system to my likings (by enabling hardware acceleration for example):

    `./1-root_setup.sh`

1. Once the first script has finished its job, you can log into Gnome and run the second script from the GUI (as normal user). It will install Yay and AUR packages defined in the array, tweak some settings such as Gnome settings, Firefox or connection settings (mDNS...), and initialize chezmoi for managing dotfiles:

    `.2-user_setup.sh`

See Archlinux wiki for details:
* [Systemd-boot] (https://wiki.archlinux.org/title/Systemd-boot)
* [Systemd-homed](https://wiki.archlinux.org/title/Systemd-homed)
* [Users and groups](https://wiki.archlinux.org/title/Users_and_groups)
* [Btrfs](https://wiki.archlinux.org/title/Btrfs)
* [GNOME] (https://wiki.archlinux.org/title/Gnome)
* [Firefox] (https://wiki.archlinux.org/title/Firefox)