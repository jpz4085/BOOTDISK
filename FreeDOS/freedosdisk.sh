#!/usr/bin/env bash
#
# Bootdisk - FreeDOS 1.4 script.
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
fmtyp="$3"
verbose="$4"
label="$5"
drive="$6"
usezenity="$7"
pipeview="false"

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mkftargs=(-F ${fstyp:3})
mtoolscfg="/tmp/mtoolsrc-fdos"
export MTOOLSRC=$mtoolscfg

if [[ ! -z $(command -v pv) ]]; then pipeview="true"; fi

if    [[ $fstyp == "FAT16" ]]; then pty=e # FAT16 LBA
elif  [[ $fstyp == "FAT32" ]]; then pty=c # FAT32 LBA
fi

if [[ "$usezenity" == "true" ]]; then
   zenprogargs='--width=300 --progress --no-cancel --title="BOOTDISK: FreeDOS"'
   zenvfmtargs='--width=550 --height=400 --text-info --title="Verbose Format Information"'
   zenwipeargs="$zenprogargs"
fi

zero_part () {
ddargs="conv=fsync oflag=direct status=none"
if   [[ $pipeview == "true" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          (echo "# Writing zeros to volume..."; pv < /dev/zero -ns $3 | \
          dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null) 2>&1 | eval zenity $zenwipeargs
     else
          pv < /dev/zero -N 'Writing zeros to volume' -pebs $3 | dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null
     fi
else
     (
     if [[ "$usezenity" == "true" ]]; then printf "# "; fi
     echo "Writing zeros to volume..."
     dd if=/dev/zero of=/dev/$1 bs=$2 $ddargs 2> /dev/null
     if [[ "$usezenity" == "true" ]]; then echo "100"; fi
     ) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenwipeargs; else cat; fi
fi
}

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
	cyls=$(fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f1 -d"/")
	hds=$(fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f2 -d"/")
	spt=$(fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f3 -d"/")
	printf 'e 1\n'$pty'\ny\n\n1\n1\n'$((cyls - 1))'\n'$((hds - 1))'\n'$spt'\nf 1\nq\n' | fdisk -y -e /dev/$drive &> /dev/null
	osascript ../Support/click_ignore.scpt &> /dev/null
	if [[ $cyls -lt 1024 ]]; then
	   #Correct partition ending cylinder (first 8 bits).
	   printf '1C5: %02X' $((cyls - 1 & 255)) | xxd -g 0 -r - /dev/$drive
	   osascript ../Support/click_ignore.scpt &> /dev/null
	fi
	if [[ $hds -lt 255 ]]; then
	   #Correct partition ending head if less than 255.
	   printf '1C3: %02X' $((hds - 1)) | xxd -g 0 -r - /dev/$drive
	   osascript ../Support/click_ignore.scpt &> /dev/null
	fi
	signature=$(dd if=/dev/random bs=1 count=4 status=none | xxd -p)
	ms-sys -a -S $signature /dev/$drive > /dev/null
	osascript ../Support/click_ignore.scpt &> /dev/null && sleep 1
	sudo chmod o+rw /dev/$drive's1'
	if [[ $fmtyp == "FULL" ]]; then
	   volume_size=$(diskutil info $drive's1' | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
	   zero_part $drive's1' '4m' $volume_size
	fi
	mkftargs+=(-u $spt -h $hds -v "$label")
	if   [[ $verbose == "true" ]]; then
	     echo "-------------------------------------"
	     newfs_msdos "${mkftargs[@]}" /dev/$drive's1'
	     echo "-------------------------------------"
	else
	     newfs_msdos "${mkftargs[@]}" /dev/$drive's1' > /dev/null
	fi
	if   [[ $pty == "e" ]]; then
	     ms-sys -5 /dev/$drive's1' > /dev/null
	elif [[ $pty == "c" ]]; then
	     ms-sys -4 /dev/$drive's1' > /dev/null
	fi
	echo "Transfer system files..."
	mcopy -s -m Files/* S:
	mmove "S:/FREEDOS/BIN/EDIT.HLP" S:
	mattrib +h S:/EDIT.HLP
	echo "Mount boot disk..."
	diskutil mount $drive's1' > /dev/null
	echo "Disable Spotlight indexing..."
	mdutil -d /Volumes/"$label" &> /dev/null
	rm $mtoolscfg
	if   [[ $fmtyp == "FULL" || $verbose == "true" ]]; then
	     read -p "Finished! Press any key to exit." -n1 -s
	else
	     echo "Finished!"; sleep 1
	fi
elif	[[ -e /dev/$drive && $system == "Linux" ]]; then
	if   [[ "$usezenity" == "true" ]]; then
	     if ! sudo -nv 2>/dev/null; then
	        zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	        if [[ $? -ne 0 ]]; then exit 1; fi
	     fi
	else
	     echo "Reading device information (sudo required)..."
        fi
        sudo chmod o+rw /dev/$drive
	disk_length=$(sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}')
	disk_size=$(blockdev --getsize64 /dev/$drive)
	disk_offset=$(($disk_length - 2048))

	echo "drive s: file=\"/dev/$drive"1"\"" > $mtoolscfg
	echo "mtools_skip_check=1" >> $mtoolscfg

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
	ms-sys -a /dev/$drive > /dev/null && sleep 1
	sudo chmod o+rw /dev/$drive"1"
	volume_size=$(blockdev --getsize64 /dev/$drive"1")
	mkftargs+=(-n "$label")
	fmtalert="false"
	if [[ $fmtyp == "FULL" ]]; then
	   if [[ $pipeview == "false" ]]; then zenwipeargs+=" --pulsate"; fi
	   zero_part $drive"1" '4M' $volume_size
	   if [[ "$usezenity" == "true" ]]; then
	      if [[ $verbose == "true" ]]; then fmtalert="true"; fi
	      echo "40"; printf "# "
	   fi
	   echo "Checking for bad blocks..."
	   mkftargs+=(-c)
	fi
	if   [[ $verbose == "true" ]]; then
	     mkftargs+=(-v)
	     echo "-------------------------------------"
	     (mkfs.fat "${mkftargs[@]}" /dev/$drive"1" && \
	     if [[ "$fmtalert" == "true" ]]; then echo "Format completed successfully."; fi) | \
	     if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
	     echo "-------------------------------------"
	else
	     mkfs.fat "${mkftargs[@]}" /dev/$drive"1" > /dev/null
	fi
	if [[ $pty == "e" ]]; then
	   ms-sys -5 /dev/$drive"1" > /dev/null
	elif [[ $pty == "c" ]]; then
	   ms-sys -4 /dev/$drive"1" > /dev/null
	fi
	if [[ "$usezenity" == "true" ]]; then echo "50"; printf "# "; fi
	echo "Transfer system files..."
	mcopy -s -m Files/* S: 2> /dev/null
	mmove "S:/FREEDOS/BIN/EDIT.HLP" S: 2> /dev/null
	mattrib +h S:/EDIT.HLP 2> /dev/null
	if [[ "$usezenity" == "true" ]]; then echo "75"; printf "# "; fi
	echo "Mount boot disk..."
	sleep 1 && gio mount -d /dev/$drive"1"
	rm $mtoolscfg
	if   [[ "$usezenity" == "false" && ($fmtyp == "FULL" || $verbose == "true") ]]; then
             read -p "Finished! Press any key to exit." -n1 -s
        else
             if [[ "$usezenity" == "true" ]]; then echo "100"; printf "# "; fi
             echo "Finished!"
             if [[ "$usezenity" == "false" ]]; then sleep 1; fi
        fi
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
