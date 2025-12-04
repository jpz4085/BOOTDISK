<a href="https://www.flaticon.com/free-icons/usb" title="USB icons created by surang - Flaticon"><img align="left" width="65" height="65" src="https://raw.githubusercontent.com/jpz4085/BOOTDISK/main/Support/usb-icon.png" alt="USB drive by Flaticon"></a>

## BOOTDISK - Flash Drive Formatting Utility and Tools

This utility consists of BASH scripts that create bootable flash drives for use on UEFI and BIOS systems. It provides functionality under macOS and Linux similar to the Rufus USB Tool for Windows. Graphical menus using Zenity are now supported on Linux.

Zenity Menu | Text Menu
:-------------:|:-----------------:
<img align="left" src="https://raw.githubusercontent.com/jpz4085/BOOTDISK/main/.github/images/Zenity Menu.png" width=406 height=502/> | <img align="right" src="https://raw.githubusercontent.com/jpz4085/BOOTDISK/main/.github/images/Text Menu.png" width=407 height=502/>

Features
--------

- Create a FreeDOS 1.4 boot disk with the basic utilities such as FDISK,FORMAT,SYS,EDIT etc.

- Create a MS-DOS boot disk using the version included with Windows from XP to 8.1.

- Create bootable Windows install media and [Windows To Go](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/deployment/windows-to-go/windows-to-go-overview) media from an ISO image.[^1]

- Create bootable Linux media that includes persistence on supported distributions. [^2]

- Create UEFI bootable exFAT or NTFS disks using the [UEFI:NTFS](https://github.com/pbatard/uefi-ntfs) bootloader.

- Create a boot disk using the pre-built [UEFI Shell](https://github.com/pbatard/UEFI-Shell) image provided by Pete Batard.

- Download official retail Windows ISOs and UEFI Shell ISOs using the [Fido](https://github.com/pbatard/Fido) script.

- Calculate the SHA-1 checksum for Windows ISO files and search the [sha1.rg-adguard.net](https://sha1.rg-adguard.net) databases.

- Customize the Windows installation process to automatically create a local account, configure privacy settings, select language and timezone settings, skip wireless network setup and disable automatic BitLocker encryption.

- Customize Windows 11 installation media to disable TPM, Secure Boot and RAM requirements.

- Additional information on the features above is available by selecting the About option.

Installation
------------------------
Download from Releases or clone the repository.
```
git clone https://github.com/jpz4085/BOOTDISK.git
```
Install, uninstall or upgrade from the previous release.
```
sudo ./setup.sh install | uninstall | upgrade
```
Click the shortcut on the app menu or run from terminal.
```
bootdisk #Graphical dialogues.
bootdisk --text-mode
```
Install any missing software packages as needed.

Dependencies
------------ 
|Required: UEFI Bootable Media|
|---|
| [7zip](https://sourceforge.net/projects/sevenzip/), curl, jq (JSON processor), bash (above 3.2 on macOS)|
  
|Recommended|Packages|
| --- | --- |
| Windows/UEFI Shell ISO downloads: | [powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |  
|Linux NTFS and exFAT Support: | ntfs-3g, exfatprogs|
|Graphical Dialogue Support: |zenity (Linux)|  
|Imaging Progress Support: |pv/pipeviewer|  
 
|Optional|Packages|
|---|---|
|Legacy BIOS and DOS media: | ms-sys, mtools|  
|Support for Windows To Go media: | wimtools, [bcd-sys](https://github.com/jpz4085/BCD-SYS)|  
|macOS NTFS Write/Format Support: | Tuxera/Paragon|  
|macOS Linux Persistence Support: |e2fsprogs|  

***Note:*** For macOS see [MacPorts](https://www.macports.org/) or [Homebrew](https://brew.sh/).

[^1]: See the Troubleshooting section of [NOTES](https://github.com/jpz4085/BOOTDISK/blob/main/Support/NOTES.md) for help if the terminal is forced closed due to a memory issue.  
[^2]: Persistence partitions are supported on Debian, Fedora, Gentoo, Ubuntu and related distributions.
