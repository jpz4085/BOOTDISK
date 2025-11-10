#!/usr/bin/env bash
#
# Bootdisk - Windows install disk script.
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
prtshm="$2"
fstyp="$3"
uefint="$4"
label="$5"
isofile="$6"
wimtools="$7"
drive="$8"
usegui="$9"
biosmode="false"
haveiso="false"

kbyte=1024
mbyte=1048576
gbyte=1073741824

endian () {
v=$1
i=${#v}

while [ $i -gt 0 ]
do
    i=$[$i-2]
    echo -n ${v:$i:2}
done
echo
}

if  [[ "$usegui" == "true" ]]; then
    usezenity="true"
    zenprogargs='--width=300 --progress --no-cancel --title="BOOTDISK: Windows Install"'
else
    usezenity="false"
fi

if [[ $prtshm == "MBR" ]]; then
   if [[ $fstyp == "FAT32" ]]; then pty=c; fi                      #FAT32 LBA
   if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]]; then pty=7; fi  #NTFS/HPFS/exFAT
   if [[ ! -z $(command -v ms-sys) ]]; then biosmode="true"; fi    #Legacy bootable.
fi
if [[ $prtshm == "GPT" ]]; then
   pty="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"   #Microsoft basic data
fi

# Verify selected ISO file then check size of install archive.
if  [[ ! -z "$isofile" && "$isofile" == *".iso"* ]]; then
    if   [[ -f "$isofile" ]]; then
         haveiso="true"
    else
         if   [[ "$usezenity" == "true" ]]; then
              zenity --error --title="File Error" --text="Unable to access Windows ISO file."
         else
              echo "Unable to access Windows ISO file."
              echo
              read -p "Press any key to continue... " -n1 -s
         fi
         exit 1
    fi
fi
if  [[ "$haveiso" == "true" ]]; then
    wimext="wim" # Extention will be renamed if using wimsplit.
    wimsize=$(7z l "$isofile" | grep install.wim | awk '{print $4}')
    if  [[ "$fstyp" == "FAT32" && $wimsize -gt $(($gbyte * 4)) ]]; then
        if  [[ $wimtools == "true" ]]; then
            wimext="swm"
        else
            if   [[ "$usezenity" == "true" ]]; then
                 zenity --width=390 --height=70 --error --title="File System Error" \
                 --text="FAT32 is not compatible with files larger than 4GBs.\
                 \nPlease install wimlib or format disk as NTFS or EXFAT."
            else
                 echo "FAT32 is not compatible with files larger than 4GBs."
                 echo "Please install wimlib or format disk as NTFS or EXFAT."
                 echo
                 read -p "Press any key to continue... " -n1 -s
            fi
            exit 1
        fi
    fi
fi

extract_files () {
isopct=0
exclude="$3"
valpct="$4"
divpct="$5"
isoextsz=$(7z l "$1" | grep 'files,' | awk '{print $3}')
if   [[ $system == "Darwin" ]]; then
     fsavail=$(df -k "$2" | awk '{print $4}' | tail -1)
elif [[ $system == "Linux" ]]; then
     bufpct=0
     fsavail=$(df --output=avail "$2" | tail -1)
fi
fsbegin=$(($fsavail * $kbyte))

if   [[ "$exclude" == "true" ]] ; then
     isoextsz=$(($isoextsz - $wimsize))
     coproc XISO (7z x "$1" -xr\!install.wim -o"$2" > /dev/null)
else
     coproc XISO (7z x "$1" -o"$2" > /dev/null)
fi

while kill -0 $XISO_PID 2> /dev/null; do
      if   [[ $system == "Darwin" ]]; then
           fsavail=$(df -k "$2" | awk '{print $4}' | tail -1)
      elif [[ $system == "Linux" ]]; then
           fsavail=$(df --output=avail "$2" | tail -1)
      fi
      if [[ "$usezenity" == "true" ]]; then echo "# Extracting ISO archive..."; fi
      isopct=$(((($fsbegin - ($fsavail * $kbyte)) * 100) / $isoextsz))
      if   [[ "$usezenity" == "true" ]]; then
           isoout=$(($valpct + ($isopct / $divpct)))
           echo $isoout
      else
           echo -ne "Extract ISO archive:" $isopct"%"\\r
      fi
done

if [[ "$usezenity" == "false" ]]; then
   echo "Extract ISO archive: 100%"
fi

if [[ $system == "Linux" ]] ; then
   coproc BUFF (sync)
   
   if [[ $fstyp == "FAT32" && "$exclude" == "false" ]] ; then
      sudo -v #Refresh credentials for unmount.
   fi
   
   if [[ "$usezenity" == "true" ]]; then
      echo "# Writing files to disk..."  
   fi
  
   while kill -0 $BUFF_PID 2> /dev/null; do
         dirty=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         bufpct=$(((($isoextsz - ($dirty * $kbyte)) * 100) / $isoextsz))
         if   [[ "$usezenity" == "true" ]]; then
              bufout=$(($isoout + ($bufpct / $divpct)))
              echo $bufout
         else
              echo -ne "Write files to disk:" $bufpct"%"\\r
         fi
   done

   if [[ "$usezenity" == "false" ]]; then
      echo "Write files to disk: 100%"
   fi
fi
}

split_install () {
valpct="$4"
fsroot=$(echo "$2" | sed 's/\/sources\/install\.swm//')

if   [[ $system == "Darwin" ]]; then
     fsavail=$(df -k "$fsroot" | awk '{print $4}' | tail -1)
elif [[ $system == "Linux" ]]; then
     fsavail=$(df --output=avail "$fsroot" | tail -1)
fi

fsbegin=$(($fsavail * $kbyte))

if [[ "$usezenity" == "true" ]]; then
   echo "# Split install archive..."
fi

coproc DIVWIM (wimsplit "$1" "$2" "$3" > /dev/null)

while kill -0 $DIVWIM_PID 2> /dev/null; do
      if   [[ $system == "Darwin" ]]; then
           fsavail=$(df -k "$fsroot" | awk '{print $4}' | tail -1)
      elif [[ $system == "Linux" ]]; then
           fsavail=$(df --output=avail "$fsroot" | tail -1)
      fi
      wimpct=$(((($fsbegin - ($fsavail * $kbyte)) * 100) / $wimsize))
      if   [[ "$usezenity" == "true" ]]; then
           wimout=$(($valpct + ($wimpct / 10)))
           echo "$wimout"
      else
           echo -ne "Split install archive:" $wimpct"%"\\r
      fi
done

if [[ "$usezenity" == "false" ]]; then
   echo "Split install archive: 100%"
fi

if [[ $system == "Linux" ]] ; then
   coproc WIM_BUFF (sync)
   
   sudo -v #Refresh credentials for unmount.
   
   if [[ "$usezenity" == "true" ]]; then
      echo "# Writing archive to disk..."  
   fi
  
   while kill -0 $WIM_BUFF_PID 2> /dev/null; do
         dirty=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         bufpct=$(((($wimsize - ($dirty * $kbyte)) * 100) / $wimsize))
         if   [[ "$usezenity" == "true" ]]; then
              bufout=$(($wimout + ($bufpct / 10)))
              echo $bufout
         else
              echo -ne "Write archive to disk:" $bufpct"%"\\r
         fi
   done

   if [[ "$usezenity" == "false" ]]; then
      echo "Write archive to disk: 100%"
   fi
fi
}

# Verify selected disk and run requested actions.
if	[[ -e /dev/$drive && $system == "Darwin" ]]; then
    ignore_btn="osascript ../Support/click_ignore.scpt" #Close macOS disk warning dialogue.
    devblksz=$(diskutil info $drive | grep 'Device Block Size:' | awk '{print $4}')
    disk_size=$(diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-)
    disk_mibsz=$(($disk_size / $mbyte)) #Disk space in whole MiBs
    disk_blocks=$((($disk_mibsz * $mbyte) / $devblksz)) #Disk space in sectors
    mibblksz=$(($mbyte / $devblksz))
	echo "Erase selected flash drive..."
	if   [[ $prtshm == "MBR" ]]; then
	     diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
	elif [[ $prtshm == "GPT" ]]; then
	     diskutil eraseDisk -noEFI "Free Space" %noformat% GPT $drive > /dev/null
	fi
	echo "Partition and format disk (sudo required)..."
    hds=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f2 -d"/")
    spt=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f3 -d"/")
	if   [[ $uefint == "Y" ]]; then
	     if   [[ $prtshm == "MBR" ]]; then
              sudo chmod o+rw /dev/$drive
              winpart=$(($disk_blocks - ($mibblksz * 2)))
	          printf 'e 1\n'$pty'\n\n'$mibblksz'\n'$winpart'\nf 1\ne 2\n1\n\n\n'$mibblksz'\nq\n' | \
	          fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
	          Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
	     elif [[ $prtshm == "GPT" ]]; then
	          if  [[ ! -z $(command -v sgdisk) ]]; then
                  diskargs=(-n '1:0:+'$(($disk_mibsz - 3))M -n 2:0:+1M -t '1:'$pty -t '2:'$pty -c 1:"$label" -c 2:UEFI_NTFS)
	              sudo sgdisk "${diskargs[@]}" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
	          else
                  diskargs=(%$pty% %noformat% $(($disk_mibsz - 2))MiB %$pty% %noformat% 1MiB "Free Space" %noformat% R)
                  diskutil partitionDisk -noEFI $drive 3 GPT "${diskargs[@]}" > /dev/null
	          fi
	     fi
	     sudo dd if=../Support/uefi-ntfs.img of=/dev/$drive's2' 2> /dev/null
	else
	     if   [[ $prtshm == "MBR" ]]; then
              sudo chmod o+rw /dev/$drive
              winpart=$(($disk_blocks - $mibblksz))
	          printf 'e 1\n'$pty'\n\n'$mibblksz'\n'$winpart'\nf 1\nq\n' | \
	          fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
	          Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
	     elif [[ $prtshm == "GPT" ]]; then
	          if  [[ ! -z $(command -v sgdisk) ]]; then
	              sudo sgdisk -I -n 0:0:0 -t '0:'$pty -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
	          else
                  diskutil eraseDisk -noEFI FAT32 %noformat% GPT $drive > /dev/null
	          fi
	     fi
	fi
    if [[ $prtshm == "MBR" && "$biosmode" == "true" ]]; then
       ms-sys -7 /dev/$drive > /dev/null && $ignore_btn &> /dev/null
    fi
	sudo chmod o+rw /dev/$drive's1'
	if   [[ $fstyp == "FAT32" ]]; then
         newfs_msdos -u $spt -h $hds -F 32 -v "$label" /dev/$drive's1' > /dev/null
         if [[ $pty == "c" && "$biosmode" == "true" ]]; then
            ms-sys -8 /dev/$drive's1' > /dev/null
         fi
	elif [[ $fstyp == "EXFAT" ]]; then
	     newfs_exfat -v "$label" /dev/$drive's1' > /dev/null
	     if [[ $pty == "7" && "$biosmode" == "true" ]]; then
            ms-sys -x /dev/$drive's1' > /dev/null
	     fi
	elif [[ $fstyp == "NTFS" ]]; then
	     personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
	     if   [[ $personality == "Tuxera" ]]; then
              spthex=$(endian $(printf '%04X' $spt))
              hdshex=$(endian $(printf '%04X' $hds))
	          /usr/local/sbin/newfs_tuxera_ntfs -v "$label" /dev/$drive's1' > /dev/null
	          echo "18: $spthex" | xxd -g 0 -r - /dev/$drive's1' #Set sectors per track per fdisk.
	          echo "1A: $hdshex" | xxd -g 0 -r - /dev/$drive's1' #Set number of heads per fdisk.
	          if [[ $pty == "7" && "$biosmode" == "true" ]]; then
                 ms-sys -n /dev/$drive's1' > /dev/null
              fi
	     elif [[ $personality == "UFSD_NTFS" ]]; then
              winpartsect=$(diskutil info $drive's1' | grep 'Partition Offset:' | awk '{print $5}' | sed 's/(//')
              winparthex=$(endian $(printf '%08X' $winpartsect))
	          ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
	          $ufsd_path/mkntfs -win7 -f -v:"$label" /dev/$drive's1' > /dev/null
	          echo "1C: $winparthex" | xxd -g 0 -r - /dev/$drive's1' #Set start sector per partition offset.
	     fi
	fi
	echo "Mount boot disk..."
	if  [[ $uefint == "Y" ]]; then
	    diskutil mountDisk $drive > /dev/null
	else
	    diskutil mount $drive's1' > /dev/null
	fi
	echo "Disable Spotlight indexing..."
	mdutil -d /Volumes/"$label" &> /dev/null
	if [[ "$haveiso" == "true" ]]; then
 	   if   [[ "$fstyp" == "FAT32" && $wimsize -gt $(($gbyte * 4)) ]]; then
 	        extract_files "$isofile" /Volumes/"$label" "true" "0" "0"
	        echo "Mount install disk image..."
	        hdiutil attach "$isofile" -mountpoint /tmp/isomount -nobrowse > /dev/null
	        split_install /tmp/isomount/sources/install.wim /Volumes/"$label"/sources/install.swm 3800 "0"
	        echo "Unmount install disk image..."
	        hdiutil detach /tmp/isomount > /dev/null
	   else
	        extract_files "$isofile" /Volumes/"$label" "false" "0" "2"
	   fi
	   if [[ ! -e /Volumes/"$label"/efi/boot/bootx64.efi ]]; then
	      echo "Copy bootmgfw.efi to the EFI boot folder..." # This should only apply to Windows 7 media.
	      7z e /Volumes/"$label"/sources/install.$wimext Windows/Boot/EFI/bootmgfw.efi -o/Volumes/"$label"/efi/boot > /dev/null && \
	      mv /Volumes/"$label"/efi/boot/bootmgfw.efi /Volumes/"$label"/efi/boot/bootx64.efi
	   fi
	fi
	if   [[ "$haveiso" == "true" ]]; then
	     read -p "Finished! Press any key to exit." -n1 -s
	else
	     echo "Finished!"
	     sleep 1
	fi
	exit 0
elif	[[ -e /dev/$drive && $system == "Linux" ]]; then
	if   [[ "$usezenity" == "true" ]]; then
	     zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	     if [[ $? -ne 0 ]]; then exit 1; fi
	else
	     echo "Reading device information (sudo required)..."
        fi
	sudo chmod o+rw /dev/$drive
	devblksz=$(blockdev --getss /dev/$drive)
	disk_size=$(blockdev --getsize64 /dev/$drive)
	disk_length=$(sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}')
	(
	echo "Unmount volumes..."
	umount /dev/$drive?
	if [[ "$usezenity" == "true" ]]; then echo "10"; printf "# "; fi
	echo "Erase MBR/GPT structures..."
	mibblksz=$(($mbyte / $devblksz))
	disk_offset=$(($disk_length - mibblksz))
	dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	if [[ "$usezenity" == "true" ]]; then echo "20"; printf "# "; fi
	echo "Prepare disk and make bootable..."
	disk_mbytes=$(($disk_size / $mbyte)) #Disk space in whole MiBs
	if [[ $uefint == "Y" ]]; then
	   if   [[ $prtshm == "MBR" ]]; then
	        echo -e ','$(($disk_mbytes - 2))M','$pty',*\n,,1' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	   elif [[ $prtshm == "GPT" ]]; then
	        echo -e 'size='$(($disk_mbytes - 3))M',type='$pty',name="'"$label"'"\nsize=1M,type='$pty',name=UEFI_NTFS' | \
	        sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	   fi
	   sudo chmod o+rw /dev/$drive"2"
	   dd if=../Support/uefi-ntfs.img of=/dev/$drive"2" 2> /dev/null
	else
	   if   [[ $prtshm == "MBR" ]]; then
	        echo ',,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null
	   elif [[ $prtshm == "GPT" ]]; then
	        echo 'type='$pty',name="'"$label"'"' | \
	        sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	   fi
	fi
	if [[ $prtshm == "MBR" && "$biosmode" == "true" ]]; then
	   ms-sys -7 /dev/$drive > /dev/null && sleep 1
	fi
	sudo chmod o+rw /dev/$drive"1"
	if [[ $fstyp == "FAT32" ]]; then
	   mkfs.fat -F 32 -n "$label" /dev/$drive"1" > /dev/null
	   if [[ $pty == "c" && "$biosmode" == "true" ]]; then
	      ms-sys -8 /dev/$drive"1" > /dev/null
	   fi
	elif [[ $fstyp == "EXFAT" ]]; then
	     mkfs.exfat -L "$label" /dev/$drive"1" > /dev/null
	elif [[ $fstyp == "NTFS" ]]; then
	     mkntfs -Q -L "$label" /dev/$drive"1" > /dev/null
	fi
	if [[ $pty == "7" && "$biosmode" == "true" ]]; then
	   ms-sys -w /dev/$drive"1" > /dev/null
	fi
	if [[ "$usezenity" == "true" ]]; then echo "30"; printf "# "; fi
	echo "Mount boot disk..." && sleep 1
	if [[ "$haveiso" == "true" ]]; then
	   if   [[ $fstyp == "FAT32" ]]; then
	        winvolopts="defaults,nosuid,nodev,uid=$(id -u),gid=$(id -g),showexec,utf8"
	        sudo mkdir /mnt/winvolume
	        sudo mount -o $winvolopts /dev/$drive"1" /mnt/winvolume
 	        if   [[ $wimsize -gt $(($gbyte * 4)) ]]; then
 	             extract_files "$isofile" /mnt/winvolume "true" "30" "10"
	             if [[ "$usezenity" == "true" ]]; then echo "55"; printf "# "; fi
	             echo "Mount install disk image..."
	             sudo mkdir -p /mnt/isomount && sudo mount -o ro,loop "$isofile" /mnt/isomount
	             split_install /mnt/isomount/sources/install.wim /mnt/winvolume/sources/install.swm 3800 "55"
	             if [[ "$usezenity" == "true" ]]; then echo "80"; printf "# "; fi
	             echo "Unmount install disk image..."
	             sudo umount /mnt/isomount && sudo rm -d /mnt/isomount
	        else
	             extract_files "$isofile" /mnt/winvolume "false" "30" "4"
	        fi
	        sudo umount /mnt/winvolume && sudo rm -r /mnt/winvolume
	        gio mount -d /dev/$drive"1"
	   else
	        gio mount -d /dev/$drive"1"
	        extract_files "$isofile" /media/$USER/"$label" "false" "30" "4"
	   fi
	   if [[ ! -e /media/$USER/"$label"/efi/boot/bootx64.efi ]]; then
	      if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
	      echo "Copy bootmgfw.efi to EFI path..." # This should only apply to Windows 7 media.
	      7z e /media/$USER/"$label"/sources/install.$wimext Windows/Boot/EFI/bootmgfw.efi -o/media/$USER/"$label"/efi/boot > /dev/null && \
	      mv /media/$USER/"$label"/efi/boot/bootmgfw.efi /media/$USER/"$label"/efi/boot/bootx64.efi
	   fi
	fi
	if   [[ "$haveiso" == "true" && "$usezenity" == "false" ]]; then
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
