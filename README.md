## BOOTDISK - Flash Drive Formatting Tool

This utility consists of a set of BASH scripts that will automatically configure removable media using GPT or MBR partition schemes and format with FAT16/32, exFAT or NTFS and the required bootstrapping code to enable startup on UEFI and BIOS systems. It provides functionality under macOS and Linux similar to the Rufus USB Tool for Windows.

Features
--------

- Create a FreeDOS 1.3 boot disk with the basic utilities such as FDISK,FORMAT,SYS,EDIT etc.

- Create a MS-DOS boot disk using the version included with Windows from XP to 8.1. (Enable from Tools Menu)

- Create bootable Windows media and extract an ISO image to the disk.

- Create UEFI bootable exFAT or NTFS disks using the [UEFI:NTFS](https://github.com/pbatard/uefi-ntfs) bootloader downloaded by the main script.

- Create a boot disk using the pre-built [UEFI Shell](https://github.com/pbatard/UEFI-Shell) image provided by Pete Batard.

- Download official retail Windows ISOs and UEFI Shell ISOs using the [Fido](https://github.com/pbatard/Fido) script. Requires [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3) 3.0 or greater.

- Customize the Windows installation process to automatically create a local account, configure privacy settings, select language and timezone settings, skip wireless network setup and disable automatic BitLocker encryption.

- Customize Windows 11 installation media for unsupported hardware (disable TPM, Secure Boot and RAM requirements).

- Additional information on the features above is available by selecting the About option.

Install/Update/Uninstall
------------------------
```
make (build exfatboot, macOS only)
sudo make install
sudo make update
sudo make uninstall
```

Requirements
------------
**Common packages:** p7zip, mtools, chntpw, powershell, and jq (JSON processor).  
Install these in addition to the packages for your platform.
See [chntpw](https://github.com/jpz4085/chntpw) for macOS.

**Linux packages:** curl, ms-sys, exfat-fuse, exfatprogs, ntfs-3g and wimtools.  
User should be member of "disk" group for unprivileged device access. 

**macOS packages:** bash (above version 3.2) and wimlib.  
These can be downloaded using MacPorts or Homebrew.  
Optionally ms-sys and sgdisk are supported if present.
