#!/bin/bash
#
# Bootdisk - Windows install disk script.
#

# Read options passed then set up format and disk variables.

system="$1"
fstyp="$2"
uefint="$3"
label="$4"
isofile="$5"
drive="$6"

if [[ $fstyp == "FAT32" ]]; then pty=c; fi                      #FAT32 LBA
if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]]; then pty=7; fi  #NTFS/HPFS/exFAT
if [[ $uefint == "Y" ]]; then num=2; else num=1; fi             #Windows media partition number.

# Verify selected drive and ISO file is valid and run actions.

if	[[ "$isofile" == *".iso"* && ! -e "$isofile" ]]; then
	echo "Unable to access Windows ISO file."
	echo
	read -p "Press any key to continue... " -n1 -s
	exit 1
elif	[[ -e /dev/$drive && $system == "Darwin" ]]; then
	echo "Erase selected flash drive..."
    diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
	echo "Prepare disk and make bootable (sudo required)..."
    if [[ $pty == "7" && $uefint == "Y" ]]; then
       printf 'e 1\n1\n\n2048\n2048\ne 2\n'$pty'\n\n\n\nf 2\nq\n' | sudo fdisk -u -f Sectors/mswinmbr.bin -y -e /dev/'r'$drive > /dev/null
       sudo dd if=../Support/uefi-ntfs.img of=/dev/$drive's1' 2> /dev/null
    else
       printf 'e 1\n'$pty'\n\n2048\n\nf 1\nq\n' | sudo fdisk -u -f Sectors/mswinmbr.bin -y -e /dev/'r'$drive > /dev/null
    fi
	osascript ../Support/click_ignore.scpt &> /dev/null
    if [[ $pty == "c" ]]; then
         sudo newfs_msdos -B Sectors/BOOTMGR/fat32pbr.bin -F 32 -v "$label" /dev/'r'$drive's1' > /dev/null
         sudo dd if=Sectors/BOOTMGR/fat32ebs.bin of=/dev/$drive's1' bs=512 seek=12 count=1 2> /dev/null
    elif [[ $pty == "7" ]]; then
         sudo newfs_exfat -v "$label" /dev/'r'$drive's'$num > /dev/null
         if [[ -e /usr/local/bin/ms-sys || -e /opt/local/bin/ms-sys ]]; then
            sudo ms-sys -w /dev/$drive's'$num > /dev/null
         else
            sudo exfatboot -B Sectors/BOOTMGR/exfatpbr.bin /dev/$drive's'$num > /dev/null
         fi
    fi
    echo "Mount boot disk..."
    if [[ $pty == "c" ]]; then
       diskutil mount $drive's1' > /dev/null
    else
       diskutil mountDisk $drive > /dev/null
    fi
    echo "Disable Spotlight indexing..."
    mdutil -d /Volumes/"$label" &> /dev/null
	if   [[ "$isofile" == *".iso"* ]]; then
         echo "Extract Windows install files..."
         7z x "$isofile" -o/Volumes/"$label" > /dev/null
	fi
	echo "Finished!"
	sleep 2
elif	[[ -e /dev/$drive && $system == "Linux" ]]; then
	disk_length=`sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}'`
	disk_offset=$(($disk_length - 2048))
    
	echo "Unmount volumes..."
	umount /dev/$drive?
	echo "Erase MBR/GPT structures..."
	dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	echo "Prepare disk and make bootable (sudo required)..."
	if [[ $pty == "7" && $uefint == "Y" ]]; then
	   echo -e ',2048,1\n,,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	   dd if=../Support/uefi-ntfs.img of=/dev/$drive"1" 2> /dev/null
	else
	   echo ',,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null
	fi
	if [[ -e /usr/local/bin/ms-sys ]]; then
	   ms-sys -7 /dev/$drive > /dev/null && sleep 1
	fi
	if [[ $pty == "c" ]]; then
	   sudo mkfs.fat -F 32 -n "$label" /dev/$drive"1" > /dev/null
	   if [[ -e /usr/local/bin/ms-sys ]]; then
	      ms-sys -8 /dev/$drive"1" > /dev/null
	   fi
	elif [[ $pty == "7" && $fstyp == "EXFAT" ]]; then
	     part_offset=`blockdev --report /dev/$drive$num | grep /dev/$drive$num | awk '{print $5}'`
	     sudo mkexfatfs -n "$label" -p $part_offset /dev/$drive$num > /dev/null
	     if [[ -e /usr/local/bin/ms-sys ]]; then
		ms-sys -w /dev/$drive$num > /dev/null
	     fi
	elif [[ $pty == "7" && $fstyp == "NTFS" ]]; then
	     sudo mkntfs -Q -L "$label" /dev/$drive$num > /dev/null
	     if [[ -e /usr/local/bin/ms-sys ]]; then
	        ms-sys -w /dev/$drive$num > /dev/null
	     fi
	fi
	echo "Mount boot disk..." && sleep 1
	gio mount -d /dev/$drive$num
	if   [[ "$isofile" == *".iso"* ]]; then
		echo "Extract Windows install files..."
		7z x "$isofile" -o/media/$USER/"$label" > /dev/null
		echo "Flush device write buffer..."
		sudo blockdev --flushbufs /dev/$drive$num
	fi
	echo "Finished!"
	sleep 1
else
	echo "Unable to access drive:" $drive
	echo
	read -p "Press any key to continue... " -n1 -s
	exit 1
fi
