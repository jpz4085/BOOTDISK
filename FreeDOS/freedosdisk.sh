#!/bin/bash
#
# Bootdisk - FreeDOS 1.2 script.
#
# Read options passed then set up format and disk variables.

system="$1"
fstyp="$2"
label="$3"
drive="$4"
fatsz=${fstyp:3}
mtoolscfg="/tmp/mtoolsrc-fdos"
export MTOOLSRC=$mtoolscfg

if    [[ $fstyp == "FAT16" ]]; then pty=e # FAT16 LBA
elif  [[ $fstyp == "FAT32" ]]; then pty=c # FAT32 LBA
fi

# Verify selected drive and format is valid and run actions.

if  [[ -e /dev/$drive && $system == "Darwin" ]]; then
    disk_size=`diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-`
    
    if  [[ $fstyp == "FAT16" && $disk_size -ge 2147483648 ]]; then
        echo "Format as FAT32 when disk is greater than 2.0GB."
        echo
        read -p "Press any key to continue... " -n1 -s
        exit 1
    fi
     
    echo "drive s: file=\"/dev/$drive"s1"\"" > $mtoolscfg
    echo "mtools_skip_check=1" >> $mtoolscfg

	echo "Erase selected flash drive..."
    diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
	echo "Prepare disk and make bootable (sudo required)..."
	printf 'e 1\n'$pty'\n\n32\n\nf 1\nq\n' | sudo fdisk -u -f Sectors/fdosmbr.bin -y -e /dev/'r'$drive > /dev/null
	osascript ../Support/click_ignore.scpt &> /dev/null
	sudo newfs_msdos -B Sectors/'fat'$fatsz'pbr'.bin -F $fatsz -v "$label" /dev/'r'$drive's1' > /dev/null
    sudo chmod g+w /dev/$drive's1'
    echo "Transfer system files..."
    mcopy -s -m Files/* S:
    mmove "S:/FDOS/BIN/EDIT.HLP" S:
    echo "Mount boot disk..."
    diskutil mount $drive's1' > /dev/null
    echo "Disable Spotlight indexing..."
    mdutil -d /Volumes/"$label" &> /dev/null
    rm $mtoolscfg
	echo "Finished!"
	echo
	sleep 2
elif   [[ -e /dev/$drive && $system == "Linux" ]]; then
	disk_length=`sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}'`
	disk_size=`blockdev --getsize64 /dev/$drive`
	disk_offset=$(($disk_length - 2048))
	mtoolscfg="/tmp/mtoolsrc-tmp"
	
	echo "drive s: file=\"/dev/$drive"1"\"" > $mtoolscfg
	echo "mtools_skip_check=1" >> $mtoolscfg
	export MTOOLSRC="$mtoolscfg"
	
	if [[ $fstyp == "FAT16" && $disk_size -ge 2147483648 ]]; then
           echo "Format as FAT32 when disk is greater than 2.0GB."
           echo
           read -p "Press any key to continue... " -n1 -s
           exit 1
        fi

	echo "Unmount volumes..."
	umount /dev/$drive?
	echo "Erase MBR/GPT structures..."
	dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	echo "Prepare disk and make bootable (sudo required)..."
	echo ',,'$pty',*;' | sudo sfdisk /dev/$drive > /dev/null
	ms-sys -w /dev/$drive > /dev/null && sleep 1
	sudo mkfs.fat -F $fatsz -n "$label" /dev/$drive"1" > /dev/null
	if [[ $pty == "e" ]]; then
	   ms-sys -5 /dev/$drive"1" > /dev/null
	elif [[ $pty == "c" ]]; then
	   ms-sys -4 /dev/$drive"1" > /dev/null
	fi
	echo "Transfer system files..."
	mcopy -s -m Files/* S:
	mmove "S:/FDOS/BIN/EDIT.HLP" S:
	echo "Mount boot disk..."
	sleep 1 && gio mount -d /dev/$drive"1"
	rm $mtoolscfg
	echo "Finished!"
	echo
	sleep 1
else
	echo "Unable to access drive:" $drive
	echo
	read -p "Press any key to continue... " -n1 -s
	exit 1
fi
