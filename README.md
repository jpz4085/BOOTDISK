## BOOTDISK - Flash Drive Formatting Tool

This utility consists of a set of BASH scripts that will automatically partition and format removable media such as flash drives with FAT16/32, exFAT or NTFS and the required bootstrapping code to enable startup on UEFI and BIOS systems. It provides some functionality under macOS/OS X and Linux like the Rufus USB Tool for Windows.

Available Selections
--------------------

- FreeDOS 1.3: Create a boot disk with the basic utilities such as FDISK,FORMAT,SYS,EDIT etc.

- MS-DOS 8.0: Create a boot disk using the DOS version included with Windows XP to 8.1. This option will only be available by extracting the DOS system files from the diskcopy.dll library found under Windows\SysWOW64 on a working system or in the same folder inside the sources\install.wim archive on Windows install media. The files are proprietary and not included with BOOTDISK.

- Windows 7-11: Create Windows bootable media using GPT or MBR partition schemes and optionally extract an ISO install image to the disk. When using exFAT or NTFS format the disk can be made UEFI bootable using [UEFI:NTFS](https://github.com/pbatard/uefi-ntfs) which is downloaded by the main script.

- UEFI Shell: Create a boot disk using the pre-built [UEFI Shell](https://github.com/pbatard/UEFI-Shell) image provided by Pete Batard.

- Tools Menu: This sub-menu provides options to enable MS-DOS 8.0 support and download Windows and UEFI
Shell ISO files using the [Fido](https://github.com/pbatard/Fido) script. This requires [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3) 3.0 or greater and is the same feature used by Rufus.

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
**Common packages:** p7zip, mtools, powershell and jq (JSON processor).  
Install these in addition to the packages for your platform.

**Linux packages:** curl, ms-sys, exfat-fuse, exfat-utils and ntfs-3g.  
User should be member of "disk" group for unprivileged device access. 

**macOS packages:** bash (above version 3.2).  
These can be downloaded using MacPorts or Homebrew.  
Optionally ms-sys and sgdisk are supported if present.
