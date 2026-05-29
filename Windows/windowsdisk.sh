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
fmtyp="$4"
verbose="$5"
uefint="$6"
label="$7"
isofile="$8"
wimtools="$9"
drive="${10}"
usezenity="${11}"
biosmode="false"
pipeview="false"

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

if [[ ! -z $(command -v pv) ]]; then pipeview="true"; fi

if  [[ "$usezenity" == "true" ]]; then
    zenprogargs='--width=300 --progress'
    if [[ $fmtyp == "FULL" && $fstyp == "FAT32" && $pipeview == "false" ]]; then
       zenprogargs+=' --pulsate'
    fi
    zenprogargs+=' --no-cancel --title="BOOTDISK: Windows Install"'
    zenvfmtargs='--width=550 --height=400 --text-info --title="Verbose Format Information"'
fi

if [[ $prtshm == "MBR" ]]; then
   if [[ $fstyp == "FAT32" ]]; then pty=c; fi                      #FAT32 LBA
   if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]]; then pty=7; fi  #NTFS/HPFS/exFAT
   if [[ ! -z $(command -v ms-sys) ]]; then biosmode="true"; fi    #Legacy bootable.
fi
if [[ $prtshm == "GPT" ]]; then
   pty="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"   #Microsoft basic data
fi

if [[ $verbose == "true" ]]; then
   boarder="-----------------------------------"
   if [[ $system == "Linux" ]]; then
      dspmode="-v"
      if [[ ($fstyp == "EXFAT" || $fstyp == "NTFS") && $fmtyp == "FULL" ]] ; then
         vbfmtinfo=$(mktemp -t vbfmtout.XXXXXXX)
      fi
   fi
fi

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
      #Refresh credentials for unmount if still active.
      if sudo -nv 2>/dev/null; then sudo -v; fi
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
   
   #Refresh credentials for unmount if still active.
   if sudo -nv 2>/dev/null; then sudo -v; fi
   
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

zero_part () {
ddargs="conv=fsync oflag=direct status=none"
if   [[ $pipeview == "true" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          (echo "# Writing zeros to volume..."; pv < /dev/zero -ns $3 | \
          dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null) 2>&1 | eval zenity $zenprogargs
     else
          pv < /dev/zero -N 'Writing zeros to volume' -pebs $3 | dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null
     fi
else
     echo "Writing zeros to volume..."
     dd if=/dev/zero of=/dev/$1 bs=$2 $ddargs 2> /dev/null
fi
}

show_progress () {
   {
   count=0
   prevsize=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
   
   while true; do
         cursize=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         if [[ ($cursize -lt $prevsize) ]]; then break; fi
         prevsize=$cursize
   done
   
   prevpct=$(((($volume_size - ($prevsize * 1024)) * 100) / $volume_size))
   if [[ "$usezenity" == "true" ]]; then printf "# "; fi
   
   if   [[ $prevpct -le 50 ]]; then
        echo "Waiting while data is buffered..."
        while true; do
              sleep 1
              cursize=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
              bufpct=$(((($volume_size - ($cursize * 1024)) * 100) / $volume_size))
              if [[ ($cursize -lt $prevsize) && ($bufpct -gt $prevpct) ]]; then ((count++)); fi
              if [[ $count -eq 5 ]]; then break; fi
              prevsize=$cursize
              prevpct=$bufpct
        done
   else
        echo "Waiting while data is written..."
        while kill -0 $BUFF_PID 2> /dev/null; do sleep 1; done
   fi
   if [[ "$usezenity" == "true" ]]; then echo "100"; fi
   } | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs --pulsate --auto-close; else cat; fi
   
   if ! kill -0 $BUFF_PID 2> /dev/null; then return; fi

   {
   while kill -0 $BUFF_PID 2> /dev/null; do
         if [[ "$usezenity" == "true" ]]; then
            echo "# Writing zeros to volume..."  
         fi
         dirty=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         bufpct=$(((($volume_size - ($dirty * 1024)) * 100) / $volume_size))
         if   [[ "$usezenity" == "true" ]]; then
              echo $bufpct
         else
              echo -ne "Writing zeros to volume:" $bufpct"%"\\r
         fi
   done

   if   [[ "$usezenity" == "true" ]]; then
        echo 100
   else
        echo "Writing zeros to volume: 100%"
   fi
   } | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
}

display_verbose () {
echo $boarder
if   [[ $fmtyp == "FULL" ]]; then
     if [[ $fstyp == "NTFS" ]]; then sed -i "$sedfmtcmds" "$vbfmtinfo"; fi # Remove extraneous lines.
     cat "$vbfmtinfo" | if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
     rm "$vbfmtinfo"
else
     readarray -u "${BUFF[0]}" vbfmtout
     printf "%s" "${vbfmtout[@]}" | if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
fi
echo $boarder
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
	if   [[ $uefint == "true" ]]; then
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
	if [[ "$biosmode" == "true" ]]; then
	   ms-sys -7 /dev/$drive > /dev/null && $ignore_btn &> /dev/null
	fi
	volume_size=$(diskutil info $drive's1' | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
	sudo chmod o+rw /dev/$drive's1'
	if   [[ $fstyp == "FAT32" ]]; then
	     mkftargs=(-u $spt -h $hds -F 32 -v "$label")
	     if [[ $fmtyp == "FULL" ]]; then
	        zero_part $drive's1' '4m' $volume_size
	     fi
	     if   [[ $verbose == "true" ]]; then
	          echo $boarder
	          newfs_msdos "${mkftargs[@]}" /dev/$drive's1'
	          echo $boarder
	     else
	          newfs_msdos "${mkftargs[@]}" /dev/$drive's1' > /dev/null
	     fi
	     if [[ "$biosmode" == "true" ]]; then
	        ms-sys -8 /dev/$drive's1' > /dev/null
	     fi
	elif [[ $fstyp == "EXFAT" ]]; then
	     if [[ $fmtyp == "FULL" ]]; then
	        zero_part $drive's1' '4m' $volume_size
	     fi
	     if   [[ $verbose == "true" ]]; then
	          echo $boarder
	          newfs_exfat -v "$label" /dev/$drive's1'
	          echo $boarder
	     else
	          newfs_exfat -v "$label" /dev/$drive's1' > /dev/null
	     fi
	     if [[ "$biosmode" == "true" ]]; then
	        ms-sys -x /dev/$drive's1' > /dev/null
	     fi
	elif [[ $fstyp == "NTFS" ]]; then
	     personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
	     if [[ $fmtyp == "FULL" ]]; then
	        zero_part $drive's1' '4m' $volume_size
	     fi
	     if   [[ $personality == "Tuxera" ]]; then
	          spthex=$(endian $(printf '%04X' $spt))
	          hdshex=$(endian $(printf '%04X' $hds))
	          if   [[ $verbose == "true" ]]; then
	               echo $boarder
	               /usr/local/sbin/newfs_tuxera_ntfs -v "$label" /dev/$drive's1'
	               echo $boarder
	          else
	               /usr/local/sbin/newfs_tuxera_ntfs -v "$label" /dev/$drive's1' > /dev/null
	          fi
	          echo "18: $spthex" | xxd -g 0 -r - /dev/$drive's1' #Set sectors per track per fdisk.
	          echo "1A: $hdshex" | xxd -g 0 -r - /dev/$drive's1' #Set number of heads per fdisk.
	          if [[ "$biosmode" == "true" ]]; then
	             ms-sys -n /dev/$drive's1' > /dev/null
	          fi
	     elif [[ $personality == "UFSD_NTFS" ]]; then
	          mkntargs=(-win7 -f -v:"$label")
	          winpartsect=$(diskutil info $drive's1' | grep 'Partition Offset:' | awk '{print $5}' | sed 's/(//')
	          winparthex=$(endian $(printf '%08X' $winpartsect))
	          ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
	          if   [[ $verbose == "true" ]]; then
	               mkntargs+=(--verbose)
	               echo $boarder
	               $ufsd_path/mkntfs "${mkntargs[@]}" /dev/$drive's1'
	               echo $boarder
	          else
	               $ufsd_path/mkntfs "${mkntargs[@]}" /dev/$drive's1' > /dev/null
	          fi
	          echo "1C: $winparthex" | xxd -g 0 -r - /dev/$drive's1' #Set start sector per partition offset.
	     fi
	fi
	echo "Mount boot disk..."
	if  [[ $uefint == "true" ]]; then
	    diskutil mountDisk $drive > /dev/null
	else
	    diskutil mount $drive's1' > /dev/null
	fi
	echo "Disable Spotlight indexing..."
	mdutil -d /Volumes/"$label" &> /dev/null
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
	read -p "Finished! Press any key to exit." -n1 -s
	exit 0
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
	if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	   zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	   if [[ $? -ne 0 ]]; then
	      echo "# Partitioning operation canceled."
              exit 1
	   fi
	fi
	disk_mbytes=$(($disk_size / $mbyte)) #Disk space in whole MiBs
	if   [[ $uefint == "true" ]]; then
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
	if [[ "$biosmode" == "true" ]]; then
	   ms-sys -7 /dev/$drive > /dev/null && sleep 1
	fi
	sudo chmod o+rw /dev/$drive"1"
	volume_size=$(blockdev --getsize64 /dev/$drive"1")
	if [[ $verbose == "false" ]]; then dspmode="-q"; fi
	if   [[ $fstyp == "FAT32" ]]; then
	     fmtalert="false"
	     mkftargs=(-F 32 -n "$label")
	     if [[ $fmtyp == "FULL" ]]; then
                zero_part $drive"1" '4M' $volume_size
                if [[ "$usezenity" == "true" ]]; then
	           if [[ $verbose == "true" ]]; then fmtalert="true"; fi
	           echo "25"; printf "# "
	        fi
                echo "Checking for bad blocks..."
                mkftargs+=(-c)
             fi
	     if   [[ $verbose == "true" ]]; then
                  mkftargs+=($dspmode)
                  echo $boarder
                  (mkfs.fat "${mkftargs[@]}" /dev/$drive"1" && \
	          if [[ "$fmtalert" == "true" ]]; then echo "Format completed successfully."; fi) | \
                  if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
                  echo $boarder
             else
                  mkfs.fat "${mkftargs[@]}" /dev/$drive"1" > /dev/null
             fi
	elif [[ $fstyp == "EXFAT" ]]; then
	     mkexfargs=($dspmode -L "$label")
	     if [[ $fmtyp == "FULL" ]]; then mkexfargs+=(-f); fi
	     if   [[ $fmtyp == "FULL" && $verbose == "true" ]]; then
                  coproc BUFF (mkfs.exfat "${mkexfargs[@]}" /dev/$drive"1") > "$vbfmtinfo"
             else
                  coproc BUFF (mkfs.exfat "${mkexfargs[@]}" /dev/$drive"1")
             fi
             if [[ $fmtyp == "FULL" ]]; then show_progress; fi
             if [[ $verbose == "true" ]]; then display_verbose; fi
             if [[ $fmtyp == "QUICK" && $verbose == "false" ]]; then wait $BUFF_PID; fi
	elif [[ $fstyp == "NTFS" ]]; then
	     mkntargs=($dspmode -L "$label")
	     if [[ $fmtyp == "QUICK" ]]; then mkntargs+=(-Q); fi
	     if   [[ $fmtyp == "FULL" && $verbose == "true" ]]; then
                  sedfmtcmds="s/Initializing device with zeroes.*Done\.//;/^$/d"
                  coproc BUFF (mkntfs "${mkntargs[@]}" /dev/$drive"1") &> "$vbfmtinfo"
             else
                  coproc BUFF (mkntfs "${mkntargs[@]}" /dev/$drive"1") 2>&1
             fi
             if [[ $fmtyp == "FULL" ]]; then show_progress; fi
             if [[ $verbose == "true" ]]; then display_verbose; fi
             if [[ $fmtyp == "QUICK" && $verbose == "false" ]]; then wait $BUFF_PID; fi
	fi
	if [[ "$biosmode" == "true" ]]; then
	   if   [[ $pty == "c" ]]; then
	        ms-sys -8 /dev/$drive"1" > /dev/null
	   elif [[ $pty == "7" ]]; then
	        ms-sys -w /dev/$drive"1" > /dev/null
	   fi
	fi
	sleep 1
	if [[ "$usezenity" == "true" ]]; then echo "30"; printf "# "; fi
	if   [[ -d "/media/$USER" ]]; then
	     media_path="/media/$USER"
	elif [[ -d "/run/media/$USER" ]]; then
	     media_path="/run/media/$USER"
	fi
	if   [[ $fstyp == "FAT32" ]]; then
	     winvolopts="defaults,nosuid,nodev,uid=$(id -u),gid=$(id -g),showexec,utf8"
	     if   ! sudo -nv 2>/dev/null; then
	          #Request credentials for mount if expired.
	          printf "Mount boot disk"
	          if   [[ "$usezenity" == "true" ]]; then
	               echo "..."; zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	          else
	               echo " (sudo required)..."
	          fi
             else
	          echo "Mount boot disk..."
	     fi
	     sudo mkdir /mnt/winvolume
	     sudo mount -o $winvolopts /dev/$drive"1" /mnt/winvolume
 	     if   [[ $wimsize -gt $(($gbyte * 4)) ]]; then
 	          extract_files "$isofile" /mnt/winvolume "true" "30" "10"
	          if [[ "$usezenity" == "true" ]]; then echo "55"; printf "# "; fi
	          echo "Mount install disk image..."
	          sudo mkdir -p /mnt/isomount && sudo mount -o ro,loop "$isofile" /mnt/isomount
	          split_install /mnt/isomount/sources/install.wim /mnt/winvolume/sources/install.swm 3800 "55"
	          if [[ "$usezenity" == "true" ]]; then echo "80"; printf "# "; fi
	          if   ! sudo -nv 2>/dev/null; then
	               printf "Unmount install disk image"
	               #Request credentials for unmount if expired.
	               if   [[ "$usezenity" == "true" ]]; then
	                    echo "..."; zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	               else
	                    echo " (sudo required)..."
	               fi
	          else
	               echo "Unmount install disk image..."
	          fi
	             sudo umount /mnt/isomount && sudo rm -d /mnt/isomount
	     else
	          extract_files "$isofile" /mnt/winvolume "false" "30" "4"
	     fi
	     if ! sudo -nv 2>/dev/null; then
	        #Request credentials for unmount if expired.
	        if   [[ "$usezenity" == "true" ]]; then
	             echo "# Remove temporary mount point..."
	             zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	        else
	             echo "Remove temporary mount point (sudo required)..."
	        fi
	     fi
	     sudo umount /mnt/winvolume && sudo rm -r /mnt/winvolume
	     gio mount -d /dev/$drive"1"
	else
	     gio mount -d /dev/$drive"1"
	     extract_files "$isofile" "$media_path/$label" "false" "30" "4"
	fi
	if [[ ! -e "$media_path/$label/efi/boot/bootx64.efi" ]]; then
	   if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
	   echo "Copy bootmgfw.efi to EFI path..." # This should only apply to Windows 7 media.
	   7z e "$media_path/$label/sources/install.$wimext" Windows/Boot/EFI/bootmgfw.efi -o"$media_path/$label/efi/boot" > /dev/null && \
	   mv "$media_path/$label/efi/boot/bootmgfw.efi" "$media_path/$label/efi/boot/bootx64.efi"
	fi
	if   [[ "$usezenity" == "true" ]]; then
	     echo "100"; echo "# Finished!"
	else
	     read -p "Finished! Press any key to exit." -n1 -s
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
