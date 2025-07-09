## BOOTDISK - Flash Drive Formatting Tool

This utility consists of BASH scripts that create bootable flash drives for use on UEFI and BIOS systems. It provides functionality under macOS and Linux similar to the Rufus USB Tool for Windows.

Features
--------

- Create a FreeDOS 1.3 boot disk with the basic utilities such as FDISK,FORMAT,SYS,EDIT etc.

- Create a MS-DOS boot disk using the version included with Windows from XP to 8.1.

- Create bootable Windows install media and [Windows To Go](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/deployment/windows-to-go/windows-to-go-overview) media from an ISO image.[^1]

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
Run at the prompt and install missing software packages.
```
bootdisk
```

Dependencies
------------ 
|Required: UEFI Bootable Media|
|---|
| [7zip](https://sourceforge.net/projects/sevenzip/), curl, jq (JSON processor), bash (above 3.2 on macOS)|
  
|Recommended|Packages|
| --- | --- |
| Windows/UEFI Shell ISO downloads: | [powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |  
|Linux NTFS and exFAT Support: | ntfs-3g, exfatprogs|
 
|Optional|Packages|
|---|---|
|Legacy BIOS and DOS media: | ms-sys, mtools|  
|Support for Windows To Go media: | wimtools, [bcd-sys](https://github.com/jpz4085/BCD-SYS)|  
|macOS NTFS Write/Format Support: | Tuxera/Paragon|  

***Note:*** For macOS see [MacPorts](https://www.macports.org/) or [Homebrew](https://brew.sh/).

[^1]: See the Troubleshooting section of [NOTES](https://github.com/jpz4085/BOOTDISK/blob/main/Support/NOTES.md) for help if the terminal is forced closed due to a memory issue.
