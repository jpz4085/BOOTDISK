#!/usr/bin/env bash
#
# Bootdisk - Disk Erasure Script.

# Read options passed then set up format and disk variables.

system="$1"
drive="$2"
prtshm="$3"
fstyp="$4"
fmtyp="$5"
verbose="$6"
uefint="$7"
label="$8"
setowner="$9"
usezenity="${10}"
udfdata=("${11}" "${12}" "${13}")
pipeview="false"

mbyte=1048576
gbyte=1073741824

RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ ! -z $(command -v pv) ]]; then pipeview="true"; fi

if  [[ "$usezenity" == "true" ]]; then
    zenprogargs='--width=300 --progress'
    if [[ $fmtyp == "FULL"* ]]; then
       if [[ $fstyp == "EXT"* || ($fstyp == "FAT"* && $pipeview == "false") ]]; then
          zenprogargs+=' --pulsate'
       fi
    fi
    zenprogargs+=' --no-cancel --title="BOOTDISK: Erase Disk"'
    zenvfmtargs='--width=550 --height=400 --text-info --title="Verbose Format Information"'
fi

if   [[ $prtshm == "MBR" ]]; then
     if [[ $fstyp == "FAT16" ]]; then pty=e; fi #FAT16 LBA
     if [[ $fstyp == "FAT32" ]]; then pty=c; fi #FAT32 LBA
     if [[ $fstyp == "EXT"* ]]; then pty=L; fi #Linux
     if [[ $fstyp == "JHFS+" ]]; then pty=AF; fi #HFS+
     if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" || $fstyp == "UDF" ]]; then pty=7; fi  #NTFS/exFAT
elif [[ $prtshm == "GPT" ]]; then
     if   [[ $fstyp == "EXT"* ]]; then
          pty="0FC63DAF-8483-4772-8E79-3D69D8477DE4" #Linux filesystem
     elif [[ $fstyp == "JHFS+" ]]; then
          pty="48465300-0000-11AA-AA11-00306543ECAC" #Apple HFS/HFS+
     elif [[ $fstyp == "APFS" ]]; then
          pty="7C3457EF-0000-11AA-AA11-00306543ECAC" #Apple APFS
     else
          pty="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" #Microsoft basic data
     fi
elif [[ $prtshm == "SFD" ]]; then
     tgtvol=$drive #Super floppy disk.
fi

if [[ $verbose == "true" ]]; then
   boarder="----------------------------------"
   if [[ $system == "Linux" ]]; then
      dspmode="-v"
      if [[ ($fstyp == "EXFAT" || $fstyp == "NTFS") && $fmtyp == "FULL" ]] ; then
         vbfmtinfo=$(mktemp -t vbfmtout.XXXXXXX)
      fi
   fi
fi

if [[ $fstyp == "FAT"* ]] ; then
   mkftargs=(-F ${fstyp:3})
fi

if [[ $fstyp == "EXT"* ]]; then
   mke2args=(-t "${fstyp,,}")
   if   [[ $fmtyp == "FULL-READ" ]]; then
        mke2args+=(-c)
   elif [[ $fmtyp == "FULL-WRITE" ]]; then
        mke2args+=(-cc)
   fi
   if [[ "$setowner" == "true" ]]; then
      mke2args+=(-E root_owner="$(id -u):$(id -g)")
   fi
   mke2args+=(-L "$label")
fi

if [[ $fstyp == "JHFS+" || $fstyp == "APFS" ]]; then
   macargs=(-v "$label")
   if [[ "$setowner" == "true" ]]; then
      macargs+=(-U $(id -u) -G $(id -g))
   fi
fi

if [[ $fstyp == "UDF" ]]; then
   udfargs=(-l "$label")
   if [[ "${udfdata[0]}" != "empty" ]]; then
      udfargs+=(--owner="${udfdata[0]}")
   fi
   if [[ "${udfdata[1]}" != "empty" ]]; then
      udfargs+=(--organization="${udfdata[1]}")
   fi
   if [[ "${udfdata[2]}" != "empty" ]]; then
      udfargs+=(--contact="${udfdata[2]}")
   fi
fi

zero_part () {
ddargs="conv=fsync oflag=direct status=none"
if   [[ $pipeview == "true" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          (echo "# Writing zeros to volume..."
          if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	      zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	      if [[ $? -ne 0 ]]; then
	         echo "# Volume erase operation canceled."
                 exit 1
	      fi
	  fi
          pv < /dev/zero -ns $3 | \
          sudo dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null) 2>&1 | eval zenity $zenprogargs
     else
          pv < /dev/zero -N 'Writing zeros to volume' -pebs $3 | sudo dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null
     fi
else
     echo "Writing zeros to volume..."
     sudo dd if=/dev/zero of=/dev/$1 bs=$2 $ddargs 2> /dev/null
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

if   [[ $system == "Darwin" && -e /dev/$drive ]]; then
     ignore_btn="osascript ../Support/click_ignore.scpt" #Close macOS disk warning dialogue.
     devblksz=$(diskutil info $drive | grep 'Device Block Size:' | awk '{print $4}')
     disk_size=$(diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-)
     disk_mibsz=$(($disk_size / $mbyte)) #Disk space in whole MiBs
     disk_blocks=$((($disk_mibsz * $mbyte) / $devblksz)) #Disk space in sectors
     mibblksz=$(($mbyte / $devblksz))
     
     if [[ $fstyp == "FAT16" && $disk_size -ge $(($gbyte * 2)) ]]; then
        if   [[ "$usezenity" == "true" ]]; then
             zenity --error --title="Format Error" --text="Format as FAT32 when disk is greater than 2.0GB."
        else
             echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
             echo
             read -p "Press any key to continue... " -n1 -s
        fi
        exit 1
     fi
     
     echo "Unmount volumes..."
     diskutil unmountDisk $drive > /dev/null
     if [[ $prtshm != "SFD" ]]; then echo "Erase selected flash drive..."; fi
     if   [[ $prtshm == "MBR" ]]; then
          diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
     elif [[ $prtshm == "GPT" ]]; then
          diskutil eraseDisk -noEFI "Free Space" %noformat% GPT $drive > /dev/null
     elif [[ $prtshm == "SFD" ]]; then
          disk_length=$(diskutil info $drive | grep "Disk Size:" | awk '{print $8}')
          disk_offset=$(($disk_length - $mibblksz))
          echo "Erase MBR/GPT structures (sudo required)..."
          sudo dd if=/dev/zero of=/dev/$drive bs=1m count=2 2> /dev/null
          sudo dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
          sleep 2
     fi
     if [[ $prtshm != "SFD" ]]; then
        echo "Create $prtshm partition table (sudo required)..."
        if [[ $fstyp == "FAT"* ]]; then
           hds=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f2 -d"/")
           spt=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f3 -d"/")
           mkftargs+=(-u $spt -h $hds)
        fi
        if   [[ $prtshm == "MBR" ]]; then
             if   [[ $uefint == "true" ]]; then
                  data_part=$(($disk_blocks - ($mibblksz * 2)))
                  printf 'e 1\n'$pty'\n\n'$mibblksz'\n'$data_part'\ne 2\n1\n\n\n'$mibblksz'\nq\n' | \
                  sudo fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
             else
                  data_part=$(($disk_blocks - $mibblksz))
                  printf 'e 1\n'$pty'\n\n'$mibblksz'\n'$data_part'\nq\n' | \
                  sudo fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
             fi
             sudo ../Windows/Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
        elif [[ $prtshm == "GPT" ]]; then
             if   [[ $uefint == "true" ]]; then
                  if  [[ ! -z $(command -v sgdisk) ]]; then
                      diskargs=(-n '1:0:+'$(($disk_mibsz - 3))M -n 2:0:+1M -t '1:'$pty -t '2:'$pty -c 1:"$label" -c 2:UEFI_NTFS)
                      sudo sgdisk "${diskargs[@]}" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                  else
                      diskargs=(%$pty% %noformat% $(($disk_mibsz - 2))MiB %$pty% %noformat% 1MiB "Free Space" %noformat% R)
                      diskutil partitionDisk -noEFI $drive 3 GPT "${diskargs[@]}" > /dev/null
                  fi
             else
                  if  [[ ! -z $(command -v sgdisk) ]]; then
                      sudo sgdisk -I -n 0:0:0 -t '0:'$pty -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                  else
                      diskutil partitionDisk -noEFI $drive 1 GPT %$pty% %noformat% R > /dev/null
                  fi
             fi
        fi
        if [[ $uefint == "true" ]]; then
           sudo dd if=uefi-ntfs.img of=/dev/$drive's2' 2> /dev/null
        fi
        volume_size=$(diskutil info $drive's1' | grep 'Disk Size:' | awk '{print $6}' | cut -c2-)
        tgtvol=$drive's1'
     fi
     if [[ $prtshm == "SFD" ]]; then sleep 1; volume_size=$disk_size; fi
     echo "Create $fstyp file system..."
     if   [[ $fstyp == "FAT"* ]]; then
          mkftargs+=(-v "$label")
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4m' $volume_size
          fi
          if   [[ $verbose == "true" ]]; then
               echo $boarder
               sudo newfs_msdos "${mkftargs[@]}" /dev/$tgtvol
               echo $boarder
          else
               sudo newfs_msdos "${mkftargs[@]}" /dev/$tgtvol > /dev/null
          fi
     elif [[ $fstyp == "EXFAT" ]]; then
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4m' $volume_size
          fi
          if   [[ $verbose == "true" ]]; then
               echo $boarder
               sudo newfs_exfat -v $label /dev/$tgtvol
               echo $boarder
          else
               sudo newfs_exfat -v $label /dev/$tgtvol > /dev/null
          fi
     elif [[ $fstyp == "NTFS" ]]; then
          personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4m' $volume_size
          fi
          if   [[ $personality == "Tuxera" ]]; then
               if   [[ $verbose == "true" ]]; then
                    echo $boarder
                    sudo /usr/local/sbin/newfs_tuxera_ntfs -v "$label" /dev/$tgtvol
                    echo $boarder
               else
                    sudo /usr/local/sbin/newfs_tuxera_ntfs -v "$label" /dev/$tgtvol > /dev/null
               fi
          elif [[ $personality == "UFSD_NTFS" ]]; then
               mkntargs=(-f -v:"$label")
               ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
               if   [[ $verbose == "true" ]]; then
                    mkntargs+=(--verbose)
                    echo $boarder
                    sudo $ufsd_path/mkntfs "${mkntargs[@]}" /dev/$tgtvol
                    echo $boarder
               else
                    sudo $ufsd_path/mkntfs "${mkntargs[@]}" /dev/$tgtvol > /dev/null
               fi
          fi
     elif [[ $fstyp == "UDF" ]]; then
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4m' $volume_size
          fi
          if   [[ $verbose == "true" ]]; then
               echo $boarder
               sudo newfs_udf -v "$label" /dev/$tgtvol
               echo $boarder
          else
               sudo newfs_udf -v "$label" /dev/$tgtvol > /dev/null
          fi
     elif [[ $fstyp == "JHFS+" || $fstyp == "APFS" ]]; then
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4m' $volume_size
          fi
          if   [[ $fstyp == "APFS" ]]; then
               sudo newfs_apfs "${macargs[@]}" /dev/$tgtvol
               tgtvol="$(diskutil info $tgtvol | grep 'APFS Container:' | awk '{print $3}')s1"
          elif [[ $fstyp == "JHFS+" ]]; then
               if   [[ $verbose == "true" ]]; then
                    echo $boarder
                    sudo newfs_hfs "${macargs[@]}" /dev/$tgtvol
                    echo $boarder
               else
                    sudo newfs_hfs "${macargs[@]}" /dev/$tgtvol > /dev/null
               fi
          fi
     fi
     if   [[ $fstyp == "UDF" ]]; then
          echo "Ejecting the disk... "
          diskutil eject $tgtvol > /dev/null
          if   [[ $prtshm == "SFD" ]]; then
               echo -e "${YELLOW}Remove the disk then reconnect before use.${NC}"
          else
               echo -e "${YELLOW}This disk is using the $prtshm partition scheme.${NC}"
               echo -e "${YELLOW}UDF format only works on macOS with SFD scheme.${NC}"
          fi
     else
          echo "Mounting the disk..." && sleep 1
          diskutil mount $tgtvol > /dev/null
          if [[ "$setowner" == "true" ]]; then
             sudo diskutil enableOwnership $tgtvol
          fi
     fi
     if   [[ $fstyp == "UDF" || $fmtyp == "FULL" || $verbose == "true" ]]; then
          read -p "Finished! Press any key to exit." -n1 -s
     else
          echo "Finished!"; sleep 1
     fi
elif [[ $system == "Linux" && -e /dev/$drive ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          if ! sudo -nv 2>/dev/null; then
	     zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	     if [[ $? -ne 0 ]]; then exit 1; fi
	  fi
     else
          echo "Reading device information (sudo required)..."
     fi
     
     devblksz=$(sudo blockdev --getss /dev/$drive)
     disk_size=$(sudo blockdev --getsize64 /dev/$drive)
     disk_length=$(sudo sfdisk -l /dev/$drive 2> /dev/null | grep "Disk /dev/$drive:" | awk '{print $7}')
     
     if [[ $fstyp == "FAT16" && $disk_size -ge $(($gbyte * 2)) ]]; then
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
     umount /dev/$drive? 2> /dev/null || umount /dev/$drive 2> /dev/null
     if [[ "$usezenity" == "true" ]]; then echo "25"; printf "# "; fi
     echo "Erase MBR/GPT structures..."
     mibblksz=$(($mbyte / $devblksz))
     disk_offset=$(($disk_length - $mibblksz))
     if [[ "$usezenity" == "true" && ! -t 0 ]]; then
        zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
        if [[ $? -ne 0 ]]; then
           echo "# Erase operation canceled."
           exit 1
        fi
     fi
     sudo dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
     sudo dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
     if [[ $prtshm != "SFD" ]]; then
        if [[ "$usezenity" == "true" ]]; then echo "50"; printf "# "; fi
        echo "Create $prtshm partition table..."
        disk_mbytes=$(($disk_size / $mbyte)) #Disk space in whole MiBs
        if   [[ $prtshm == "MBR" ]]; then
             if   [[ $uefint == "true" ]]; then
                  echo -e ','$(($disk_mbytes - 2))M','$pty',*\n,,1' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
             else
                  echo ',,'$pty'' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
             fi
        elif [[ $prtshm == "GPT" ]]; then
             if   [[ $uefint == "true" ]]; then
                  echo -e 'size='$(($disk_mbytes - 3))M',type='$pty',name="'"$label"'"\nsize=1M,type='$pty',name=UEFI_NTFS' | \
                  sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
             else
                  echo 'type='$pty',name="'"$label"'"' | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
             fi
        fi
        if [[ $uefint == "true" ]]; then
           sudo dd if=uefi-ntfs.img of=/dev/$drive"2" 2> /dev/null
        fi
        volume_size=$(sudo blockdev --getsize64 /dev/$drive"1")
        tgtvol=$drive"1"
     fi
     if [[ $verbose == "false" ]]; then dspmode="-q"; fi
     if [[ $prtshm == "SFD" ]]; then sleep 1; volume_size=$disk_size; fi
     if [[ "$usezenity" == "true" ]]; then echo "75"; printf "# "; fi
     echo "Create $fstyp file system..."
     if   [[ $fstyp == "FAT"* ]]; then
          fmtalert="false"
          mkftargs+=(-n "$label")
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4M' $volume_size
             if [[ "$usezenity" == "true" ]]; then
	        if [[ $verbose == "true" ]]; then fmtalert="true"; fi
	        echo "80"; printf "# "
	     fi
             echo "Checking for bad blocks..."
             mkftargs+=(-c)
          fi
          if   [[ $verbose == "true" ]]; then
               mkftargs+=($dspmode)
               echo $boarder
               (if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	           zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	           if [[ $? -ne 0 ]]; then exit 1; fi
	       fi
               sudo mkfs.fat "${mkftargs[@]}" /dev/$tgtvol && \
	       if [[ "$fmtalert" == "true" ]]; then echo "Format completed successfully."; fi) | \
               if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
               echo $boarder
          else
               sudo mkfs.fat "${mkftargs[@]}" /dev/$tgtvol > /dev/null
          fi
     elif [[ $fstyp == "EXT"* ]] ; then
          mke2args+=($dspmode)
          if [[ $verbose == "true" ]]; then echo $boarder; fi
          sudo mke2fs "${mke2args[@]}" /dev/$tgtvol | \
          if [[ "$usezenity" == "true" && $verbose == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
          if [[ $verbose == "true" ]]; then echo $boarder; fi
     elif [[ $fstyp == "EXFAT" ]]; then
          mkexfargs=($dspmode -L "$label")
          if [[ $fmtyp == "FULL" ]]; then mkexfargs+=(-f); fi
          if   [[ $fmtyp == "FULL" && $verbose == "true" ]]; then
               coproc BUFF (sudo mkfs.exfat "${mkexfargs[@]}" /dev/$tgtvol) > "$vbfmtinfo"
          else
               coproc BUFF (sudo mkfs.exfat "${mkexfargs[@]}" /dev/$tgtvol)
          fi
          if [[ $fmtyp == "FULL" ]]; then show_progress; fi
          if [[ $verbose == "true" ]]; then display_verbose; fi
          if [[ $fmtyp == "QUICK" && $verbose == "false" ]]; then wait $BUFF_PID; fi
     elif [[ $fstyp == "NTFS" ]]; then
          mkntargs=($dspmode -L "$label")
          if [[ $prtshm == "SFD" ]]; then mkntargs+=(-F); fi
          if [[ $fmtyp == "QUICK" ]]; then mkntargs+=(-Q); fi
          if   [[ $fmtyp == "FULL" && $verbose == "true" ]]; then
               sedfmtcmds="s/Initializing device with zeroes.*Done\.//;/^$/d"
               coproc BUFF (sudo mkntfs "${mkntargs[@]}" /dev/$tgtvol) &> "$vbfmtinfo"
          else
               coproc BUFF (sudo mkntfs "${mkntargs[@]}" /dev/$tgtvol) 2>&1
          fi
          if [[ $fmtyp == "FULL" ]]; then show_progress; fi
          if [[ $verbose == "true" ]]; then display_verbose; fi
          if [[ $fmtyp == "QUICK" && $verbose == "false" ]]; then wait $BUFF_PID; fi
     elif [[ $fstyp == "UDF" ]]; then
          if [[ $fmtyp == "FULL" ]]; then
             zero_part $tgtvol '4M' $volume_size
          fi
          if   [[ $verbose == "true" ]]; then
               echo $boarder
               sudo mkudffs "${udfargs[@]}" /dev/$tgtvol |& \
               if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
               echo $boarder
          else
               sudo mkudffs "${udfargs[@]}" /dev/$tgtvol &> /dev/null
          fi
     fi
     if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
     echo "Mount the disk..." && sleep 1
     gio mount -d /dev/$tgtvol
     if [[ $? -ne 0 ]]; then
        if   [[ "$usezenity" == "true" ]]; then
             zenity --error --title="Mount Error" --text="Unable to mount: /dev/$tgtvol."
        else
             echo "${RED}Mount operation failed.${NC}"
             echo
             read -p "Press any key to continue... "
        fi
        exit 1
     fi
     if   [[ "$usezenity" == "false" && ($fmtyp == "FULL" || $verbose == "true") ]]; then
          read -p "Finished! Press any key to exit." -n1 -s
     else
          if [[ "$usezenity" == "true" ]]; then echo "100"; printf "# "; fi
          echo "Finished!"
          if [[ "$usezenity" == "false" ]]; then sleep 1; fi
     fi
     ) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
     exit 0
else
     if   [[ "$usezenity" == "true" ]]; then
          zenity --error --title="Device Error" --text="Unable to access: $drive."
     else
          echo "Unable to access:" $drive
          echo
          read -p "Press any key to continue... " -n1 -s
     fi
     exit 1
fi
