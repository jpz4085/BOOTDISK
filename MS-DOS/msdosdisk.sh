#!/usr/bin/env bash
#
# Bootdisk - MS-DOS 8.0 script.
#
# Read options passed then set up format and disk variables.
#
# Copyright (C) 2024 Joseph P. Zeller
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

system="$1"
fstyp="$2"
label="$3"
drive="$4"
usegui="$5"
fatsz=${fstyp:3}

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mtoolscfg="/tmp/mtoolsrc-msdos"
export MTOOLSRC=$mtoolscfg

if    [[ $fstyp == "FAT16" ]]; then pty=e # FAT16 LBA
elif  [[ $fstyp == "FAT32" ]]; then pty=c # FAT32 LBA
fi

if  [[ "$usegui" == "true" ]]; then
    usezenity="true"
    zenprogargs='--width=300 --progress --no-cancel --title="BOOTDISK: MS-DOS"'
else
    usezenity="false"
fi

# Verify selected drive and format is valid and run actions.

if	[[ -e /dev/$drive && $system == "Darwin" ]]; then
	disk_size=$(diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-)
    
	if [[ $fstyp == "FAT16" && $disk_size -ge 2147483648 ]]; then
	   echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
	   echo
	   read -p "Press any key to continue... " -n1 -s
	   exit 1
	fi
     
	echo "drive s: file=\"/dev/$drive"s1"\"" > $mtoolscfg
	echo "mtools_skip_check=1" >> $mtoolscfg

	echo "Erase selected flash drive..."
	diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
	echo "Prepare disk and make bootable (sudo required)..."
	sudo chmod o+rw /dev/$drive
	printf 'e 1\n'$pty'\n\n32\n\nf 1\nq\n' | fdisk -y -e /dev/$drive &> /dev/null
	osascript ../Support/click_ignore.scpt &> /dev/null
	signature=$(dd if=/dev/random bs=1 count=4 status=none | xxd -p)
	ms-sys -9 -S $signature /dev/$drive > /dev/null
	osascript ../Support/click_ignore.scpt &> /dev/null && sleep 1
	sudo chmod o+rw /dev/$drive's1'
	newfs_msdos -F $fatsz -v "$label" /dev/$drive's1' > /dev/null
	ms-sys -w /dev/$drive's1' > /dev/null
	echo "Transfer system files..."
	mcopy -s -m Files/* S:
	mattrib +s +h +r S:/IO.SYS
	mattrib +s +h +r S:/MSDOS.SYS
	mattrib +r S:/COMMAND.COM
	echo "Mount boot disk..."
	diskutil mount $drive's1' > /dev/null
	echo "Disable Spotlight indexing..."
	mdutil -d /Volumes/"$label" &> /dev/null
	rm $mtoolscfg
	echo "Finished!"
	sleep 1
elif	[[ -e /dev/$drive && $system == "Linux" ]]; then
	if   [[ "$usezenity" == "true" ]]; then
	     zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	     if [[ $? -ne 0 ]]; then exit 1; fi
	else
	     echo "Reading device information (sudo required)..."
        fi
	sudo chmod o+rw /dev/$drive
	disk_length=$(sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}')
	disk_size=$(blockdev --getsize64 /dev/$drive)
	disk_offset=$(($disk_length - 2048))

	if [[ $fstyp == "FAT16" && $disk_size -ge 2147483648 ]]; then
	   if   [[ "$usezenity" == "true" ]]; then
	        zenity --error --title="Format Error" --text="Format as FAT32 when disk is greater than 2.0GB."
	   else
	        echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
	        echo
	        read -p "Press any key to continue... " -n1 -s
	   fi
	   exit 1
	fi

	(
	echo "drive s: file=\"/dev/$drive"1"\"" > $mtoolscfg
	echo "mtools_skip_check=1" >> $mtoolscfg

	echo "Unmount volumes..."
	umount /dev/$drive?
	if [[ "$usezenity" == "true" ]]; then echo "10"; printf "# "; fi
	echo "Erase MBR/GPT structures..."
	dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	if [[ "$usezenity" == "true" ]]; then echo "30"; printf "# "; fi
	echo "Prepare disk and make bootable..."
	if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	   zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	   if [[ $? -ne 0 ]]; then
	      echo "# Partitioning operation canceled."
              exit 1
	   fi
	fi
	echo ',,'$pty',*;' | sudo sfdisk /dev/$drive > /dev/null
	ms-sys -9 /dev/$drive > /dev/null && sleep 1
	sudo chmod o+rw /dev/$drive"1"
	mkfs.fat -F $fatsz -n "$label" /dev/$drive"1" > /dev/null
	ms-sys -w /dev/$drive"1" > /dev/null
	if [[ "$usezenity" == "true" ]]; then echo "50"; printf "# "; fi
	echo "Transfer system files..."
	mcopy -s -m Files/* S: 2> /dev/null
	mattrib +s +h +r S:/IO.SYS 2> /dev/null
	mattrib +s +h +r S:/MSDOS.SYS 2> /dev/null
	mattrib +r S:/COMMAND.COM 2> /dev/null
	if [[ "$usezenity" == "true" ]]; then echo "70"; printf "# "; fi
	echo "Mount boot disk..."
	sleep 1 && gio mount -d /dev/$drive"1"
	rm $mtoolscfg
	if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
	echo "Finished!"
	if [[ "$usezenity" == "true" ]]; then echo "100"; else sleep 1; fi
	) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
else
	if   [[ "$usezenity" == "true" ]]; then
	     zenity --error --title="Device Error" --text="Unable to access disk: $drive."
	else
	     echo "Unable to access drive:" $drive
	     echo
	     read -p "Press any key to continue... " -n1 -s
	fi
	exit 1
fi
