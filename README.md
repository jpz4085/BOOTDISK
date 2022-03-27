## BOOTDISK - Flash Drive Formatting Tool

This utility consists of a set of BASH scripts that will automatically partition and format removable media such as flash drives with FAT16/32, exFAT or NTFS and the required bootstrapping code to enable startup on UEFI and BIOS systems. It provides some functionality under macOS/OS X and Linux like the Rufus USB Tool for Windows.

### Available Selections

- FreeDOS 1.2: Create a boot disk with the basic utilities such as FDISK,FORMAT,SYS,EDIT etc.

- MS-DOS 8.0: Create a boot disk using the DOS version included with Windows XP to 8.1. This option will only be available by extracting the DOS system files from the diskcopy.dll library found under Windows\SysWOW64 on a working system or in the same folder inside the install.wim archive on Windows ISO media. The files are proprietary and not included with BOOTDISK.

- Windows 7-10: Create Windows bootable media using GPT or MBR partition schemes and optionally extract an ISO install image to the disk. When using exFAT or NTFS format the disk can be made UEFI bootable using [UEFI:NTFS](https://github.com/pbatard/uefi-ntfs) which is downloaded by the main script.

### Install/Update/Uninstall
```
make (build exfatboot, macOS only)
sudo make install
sudo make update
sudo make uninstall
```

### MS-DOS 8.0 Support

Place the diskcopy.dll library from a Windows XP/7/8 installation or media in the Support folder then run the script as shown below.
```
cd /usr/local/share/BOOTDISK
sudo ./extract_msdos.sh
```
This can also be done before installation of BOOTDISK without requiring sudo.

### Requirements

Linux packages: curl, p7zip, ms-sys, mtools, exfat-fuse, exfat-utils and ntfs-3g. User should be member of "disk" group to allow unprivileged device access.  
macOS packages: p7zip, mtools and bash (above version 3.2). These can be downloaded using MacPorts or Homebrew. Optionally ms-sys and sgdisk are supported if present.
