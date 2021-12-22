				*************************************
				BOOTDISK: Flash Drive Formatting Tool
				*************************************
				
ABOUT

This utility consists of a set of BASH scripts that will automatically partition and format removable
media such as flash drives with FAT16/32, exFAT or NTFS and the required bootstrapping code to enable
startup on UEFI and BIOS systems. It provides some functionality like the Rufus USB Tool for Windows.

Available selections:
=====================

FreeDOS 1.2 – Create a boot disk containing a basic set of utilities like FDISk,FORMAT,SYS,EDIT,etc.

MS-DOS 8.0 – Create a boot disk using the DOS version included with Windows XP to 8.1. The DOS system
files must be extracted from diskcopy.dll and patched using the script provided in the Support folder.
The library can be found under Windows\SysWOW64 on a working system or inside install.wim on ISO media.

Windows – Create a bootable Windows installation disk and optionally extract an ISO image to the disk.
Under Linux the ISO file path must not contain single quotes so copy/paste the file into terminal but
not drag and drop. When using exFAT or NTFS format the disk can be made UEFI bootable using UEFI:NTFS
which is downloaded automatically when launching the main script.

Requirements:
=============

Supported on Linux and macOS with the appropriate packages installed as listed below.

Linux requires curl, p7zip, ms-sys, mtools, exfat-fuse, exfat-utils and ntfs-3g. See the documentation
for your distribution. If no legacy boot support if desired for some reason then ms-sys can be omitted
and the script can be used to create UEFI bootable Windows media only.

macOS requires p7zip and mtools but can optionally use ms-sys for legacy EXFAT boot support instead of
the exfatboot utility. Apple provides no NTFS formatting or write support so neither does the script.
