<!-- <div align="center"> -->
<img src="https://github.com/archlinux/archinstall/raw/master/docs/logo.png" alt="drawing" width="200"/>

<!-- </div> -->
# Arch installer tools

Just some files and scripts to ease the Arch installation process. Install a fresh Archlinux system first by using the new [Archinstall](https://github.com/archlinux/archinstall) script. *(**Note**: the script must be run from an Archlinux live ISO booted into EFI mode)*. The [user configuration file](https://github.com/Jucgshu/archinstall/blob/main/user_configuration.json) can be used to speed up the process.

    $ archinstall --config /var/log/archinstall/user_configuration.json --disk-layout <path to disk layout config file or URL> --creds <path to user credentials config file or URL>

# Usage
After installing Archlinux, you can enable systemd-homed:

    $ systemctl enable --now systemd-homed.service

You can then create an admin user:

    $ homectl create MyUser --shell=/usr/bin/zsh --member-of=wheel --storage=subvolume

See Archlinux wiki for details:
* [Systemd-homed](https://wiki.archlinux.org/title/Systemd-homed)
* [Users and groups](https://wiki.archlinux.org/title/Users_and_groups)
* [Btrfs](https://wiki.archlinux.org/title/Btrfs)

You should also enable sudo for members of the wheel group by running the `EDITOR=vim visudo` command.

## Configuration files to ease the Arch installation process.

|File|Description|Reference|
|-|-|-|
|user_configuration.json|Main Arch configuration file, based on archinstall script|[Archinstall](https://github.com/archlinux/archinstall)|
|archsetup.sh|Archlinux post installation script|
|Firefox/prefs.js|Main Firefox user configuration file, based on privacy settings & personal preferences|[Firefox Profilemaker](https://ffprofile.com/)|
