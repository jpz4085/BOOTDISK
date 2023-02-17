#!/usr/bin/env bash
#
# Bootdisk - UEFI Shell script.

# Read options passed then set up format and disk variables.

system="$1"
isofile="$2"
drive="$3"
prtshm="$4"
fstyp="$5"
label="$6"
fatsz=${fstyp:3}

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ $prtshm == "MBR" ]]; then
   if [[ $fstyp == "FAT16" ]]; then pty=e; fi #FAT16 LBA
   if [[ $fstyp == "FAT32" ]]; then pty=c; fi #FAT32 LBA
   erase="true"
fi
if [[ $prtshm == "GPT" ]]; then
   pty="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" #Microsoft basic data
   erase="true"
fi
if [[ $prtshm == "CURRENT" ]]; then
   erase="false"
fi

ignore_btn="osascript ./click_ignore.scpt" #Close macOS disk warning dialogue.

extract_shell () {
echo "Extract UEFI Shell files..."
7z x "$1" -o"$2" > /dev/null
echo "Finished!" && sleep 2
}

# Verify selected drive and ISO file is valid and run actions.

if    [[ "$isofile" == *".iso"* && ! -e "$isofile" ]]; then
      echo "Unable to access ISO file. Try again."
      echo
      read -p "Press any key to continue... " -n1 -s
      exit 1
elif  [[ $erase == "true" && -e /dev/$drive ]]; then
      if  [[ $system == "Darwin" ]]; then
          disk_size=`diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-`

	  if [[ $fstyp == "FAT16" && $disk_size -ge 2147483648 ]]; then
	     echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
	     echo
	     read -p "Press any key to continue... " -n1 -s
	     exit 1
	  fi
	  
          echo "Erase selected flash drive..."
          if   [[ $prtshm == "MBR" ]]; then
	       diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
	  elif [[ $prtshm == "GPT" ]]; then
	       diskutil eraseDisk "Free Space" %noformat% GPT $drive > /dev/null
	  fi
          echo "Partition and format disk (sudo required)..."
          sudo chmod o+rw /dev/'r'$drive
          if   [[ $prtshm == "MBR" ]]; then
               printf 'e 1\n'$pty'\n\n2048\n\n\nq\n' | fdisk -y -e /dev/'r'$drive &> /dev/null && $ignore_btn &> /dev/null
          elif [[ $prtshm == "GPT" ]]; then
	       if  [[ -e /usr/local/bin/sgdisk ]]; then
	           sgdisk -o /dev/'r'$drive > /dev/null 2>&1
	           sgdisk -n 0:0:0 -t '0:'$pty -c 0:"$label" /dev/'r'$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
	       else
	           gpt remove -a /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	           gpt add -t $pty /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	           gpt label -i 1 -l "$label" /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	       fi
	  fi
	  sudo chmod o+rw /dev/'r'$drive's1'
          newfs_msdos -F $fatsz -v "$label" /dev/'r'$drive's1' > /dev/null
          echo "Mount boot disk..."
          diskutil mount $drive's1' > /dev/null
          echo "Disable Spotlight indexing..."
          mdutil -d /Volumes/"$label" &> /dev/null
          extract_shell "$isofile" /Volumes/"$label"
      fi
      if  [[ $system == "Linux" ]]; then
          disk_length=`sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}'`
          disk_size=`blockdev --getsize64 /dev/$drive`
	  disk_offset=$(($disk_length - 2048))
	  
	  if [[ $fstyp == "FAT16" && $disk_size -ge 2147483648 ]]; then
	     echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
	     echo
	     read -p "Press any key to continue... " -n1 -s
	     exit 1
	  fi

	  echo "Unmount volumes..."
	  umount /dev/$drive?
	  echo "Erase MBR/GPT structures..."
	  dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	  dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	  echo "Partition and format disk (sudo required)..."
	  if   [[ $prtshm == "MBR" ]]; then
	       echo ',,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	  elif [[ $prtshm == "GPT" ]]; then
	       echo 'type='$pty',name="'"$label"'"' | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	  fi
	  mkfs.fat -F $fatsz -n "$label" /dev/$drive"1" > /dev/null
	  echo "Mount boot disk..." && sleep 1
	  gio mount -d /dev/$drive"1"
	  extract_shell "$isofile" /media/$USER/"$label"
      fi
elif  [[ $erase == "false" && -e "$drive" ]]; then
      extract_shell "$isofile" "$drive"
else
      echo "Unable to access:" $drive
      echo
      read -p "Press any key to continue... " -n1 -s
      exit 1
fi
