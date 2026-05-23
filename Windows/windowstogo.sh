#!/usr/bin/env bash

#  Bootdisk - Windows To Go Script.
#  
#  Based on the WTG PowerShell procedure at the link below.
#  https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/deployment/windows-to-go/deploy-windows-to-go
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
wimfile="$2"
fmtyp="$3"
verbose="$4"
image="$5"
drive="$6"
usezenity="$7"
mbyte=1048576
biosmode="false"
pipeview="false"
hivepath="Windows/System32/config/SYSTEM"
winrepath="Windows/System32/Recovery/Winre.wim"
prodname=$(wiminfo "$wimfile" $image | grep -m 1 Name: | sed "s/^.*: *//" | awk '{printf ("%s %s", $1, $2)}')

if [[ ! -z $(command -v ms-sys) ]]; then biosmode="true"; fi #Legacy BIOS bootable otherwise UEFI only.
if [[ ! -z $(command -v pv) && $system == "Darwin" ]]; then pipeview="true"; fi #Use pipeviewer under macOS.

if [[ "$usezenity" == "true" ]]; then
   usezenity="true"
   zenprogargs='--progress --no-cancel --title="BOOTDISK: Windows To Go"'
   zenvfmtargs='--width=550 --height=400 --text-info --title="Verbose Format Information"'
fi

if [[ $verbose == "true" ]]; then
   boarder="------------------------------------"
   if [[ $system == "Linux" ]]; then
      dspmode="-v"
      if [[ $fmtyp == "FULL" ]]; then vbfmtinfo=$(mktemp -t vbfmtout.XXXXXXX); fi
   fi
fi

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
        echo "Zeros are being written to the Windows volume..."
        while kill -0 $BUFF_PID 2> /dev/null; do sleep 1; done
   fi
   if [[ "$usezenity" == "true" ]]; then echo "100"; fi
   } | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs --pulsate --auto-close; else cat; fi
   
   if ! kill -0 $BUFF_PID 2> /dev/null; then return; fi

   {
   while kill -0 $BUFF_PID 2> /dev/null; do
         if [[ "$usezenity" == "true" ]]; then
            echo "# Writing zeros to the Windows volume..."  
         fi
         dirty=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         bufpct=$(((($volume_size - ($dirty * 1024)) * 100) / $volume_size))
         if   [[ "$usezenity" == "true" ]]; then
              echo $bufpct
         else
              echo -ne "Writing zeros to the Windows volume:" $bufpct"%"\\r
         fi
   done

   if   [[ "$usezenity" == "true" ]]; then
        echo 100
   else
        echo "Writing zeros to the Windows volume: 100%"
   fi
   } | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
}

display_verbose () {
echo $boarder
if   [[ $fmtyp == "FULL" ]]; then
     sed -i "$sedfmtcmds" "$vbfmtinfo" # Remove extraneous lines.
     cat "$vbfmtinfo" | if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
     rm "$vbfmtinfo"
else
     readarray -u "${BUFF[0]}" vbfmtout
     printf "%s" "${vbfmtout[@]}" | if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
fi
echo $boarder
}

if    [[ -e /dev/$drive && $system == "Darwin" ]]; then
      ignore_btn="osascript ../Support/click_ignore.scpt" #Ignore disk warnings.
      devblksz=$(diskutil info $drive | grep 'Device Block Size:' | awk '{print $4}')
      disk_size=$(diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-)
      disk_mibsz=$(($disk_size / $mbyte)) #Disk space in whole MiBs
      disk_blocks=$((($disk_mibsz * $mbyte) / $devblksz)) #Disk space in sectors
      bcdargs=("-f" "both" "/Volumes/UFD-Windows" "-s" "/Volumes/UFD-SYSTEM" "-n" "$prodname")
      mibblksz=$(($mbyte / $devblksz))
      syspartsz=$(($mibblksz * 350))
      winpartsect=$(($mibblksz * 351))
      echo "Erase selected flash drive..."
      diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
      echo "Prepare disk and make bootable (sudo required)..."
      sudo chmod o+rw /dev/$drive
      hds=$(fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f2 -d"/")
      spt=$(fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f3 -d"/")
      winpartsz=$(($disk_blocks - $winpartsect))
      dd if=/dev/zero of=/dev/$drive bs=1m seek=351 count=1 2> /dev/null #Wipe start of Windows area.
      printf 'e 1\nc\n\n'$mibblksz'\n'$syspartsz'\nf 1\ne 2\n7\n\n\n'$winpartsz'\nq\n' | \
      fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
      Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
      if [[ "$biosmode" == "true" ]]; then
         ms-sys -7 /dev/$drive > /dev/null && $ignore_btn &> /dev/null
      fi
      sudo chmod o+rw /dev/$drive's1' /dev/$drive's2'
      if [[ $fmtyp == "FULL" ]]; then
         if   [[ $pipeview == "true" ]]; then
              volume_size=$(diskutil info $drive's1' | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
              pv < /dev/zero -N "Writing zeros to system volume" -pebs $volume_size -o /dev/$drive's1'
         else
              echo "Writing zeros to system volume..."
              diskutil zeroDisk $drive's1' > /dev/null
         fi
      fi
      mkftargs=(-u $spt -h $hds -F 32 -v "UFD-SYSTEM")
      if   [[ $verbose == "true" ]]; then
           echo "Creating FAT32 file system on system volume..."
           echo "$boarder"
           newfs_msdos "${mkftargs[@]}" /dev/$drive's1'
           echo "$boarder"
      else
           newfs_msdos "${mkftargs[@]}" /dev/$drive's1' > /dev/null
      fi
      if [[ "$biosmode" == "true" ]]; then
         ms-sys -8 /dev/$drive's1' > /dev/null
      fi
      personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
      if   [[ $personality == "Tuxera" ]]; then
           spthex=$(endian $(printf '%04X' $spt))
           hdshex=$(endian $(printf '%04X' $hds))
           if [[ $fmtyp == "FULL" ]]; then
              if   [[ $pipeview == "true" ]]; then
                   volume_size=$(diskutil info $drive's2' | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                   pv < /dev/zero -N "Writing zeros to Windows volume" -pebs $volume_size -o /dev/$drive's2'
              else
                   echo "Writing zeros to Windows volume..."
                   diskutil zeroDisk $drive's2' > /dev/null
              fi
           fi
           if   [[ $verbose == "true" ]]; then
                echo "Creating NTFS file system on Windows volume..."
                echo $boarder
                /usr/local/sbin/newfs_tuxera_ntfs -v "UFD-Windows" /dev/$drive's2'
                echo $boarder
           else
                /usr/local/sbin/newfs_tuxera_ntfs -v "UFD-Windows" /dev/$drive's2' > /dev/null
           fi
           echo "18: $spthex" | xxd -g 0 -r - /dev/$drive's2' #Set sectors per track per fdisk.
           echo "1A: $hdshex" | xxd -g 0 -r - /dev/$drive's2' #Set number of heads per fdisk.
      elif [[ $personality == "UFSD_NTFS" ]]; then
           mkntargs=(-win7 -f -v:"UFD-Windows")
           winparthex=$(endian $(printf '%08X' $winpartsect))
           ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
           if [[ $fmtyp == "FULL" ]]; then
              if   [[ $pipeview == "true" ]]; then
                   volume_size=$(diskutil info $drive's2' | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                   pv < /dev/zero -N "Writing zeros to Windows volume" -pebs $volume_size -o /dev/$drive's2'
              else
                   echo "Writing zeros to Windows volume..."
                   diskutil zeroDisk $drive's2' > /dev/null
              fi
           fi
           if   [[ $verbose == "true" ]]; then
                mkntargs+=(--verbose)
                echo "Creating NTFS file system on Windows volume..."
                echo $boarder
                $ufsd_path/mkntfs "${mkntargs[@]}" /dev/$drive's2'
                echo $boarder
           else
                $ufsd_path/mkntfs "${mkntargs[@]}" /dev/$drive's2' > /dev/null
           fi
           echo "1C: $winparthex" | xxd -g 0 -r - /dev/$drive's2' #Set start sector to (351MiB) offset.
      else
           mkntargs=(-L "UFD-Windows" -p $winpartsect -H $hds -S $spt)
           if [[ $fmtyp == "QUICK" ]]; then
              mkntargs+=(-Q)
              if [[ $verbose == "false" ]]; then mkntargs+=(-q); fi
           fi
           if [[ $verbose == "true" ]]; then
              mkntargs+=(-v)
              echo "Creating NTFS file system on Windows volume..."
              echo $boarder
           fi
           mkntfs "${mkntargs[@]}" /dev/$drive's2'
           if [[ $verbose == "true" ]]; then echo $boarder; fi
      fi
      wimapply "$wimfile" $image /dev/$drive's2' 2> /tmp/wimfile_errors.txt
      if [[ ! $? -eq 0 ]]; then cat /tmp/wimfile_errors.txt; exit 1; fi
      echo "Mount the partitions..."
      diskutil mount $drive's1' > /dev/null
      diskutil mount $drive's2' > /dev/null
      echo "Disable Spotlight indexing..."
      mdutil -d "/Volumes/UFD-SYSTEM" &> /dev/null
      mdutil -d "/Volumes/UFD-Windows" &> /dev/null
      echo "Setup the Windows boot files..."
      bcd-sys "${bcdargs[@]}"
      if [[ ! $? -eq 0 ]]; then exit 1; fi
      echo "Set internal disks to offline..."
      hivexregedit --merge --prefix SYSTEM "/Volumes/UFD-Windows/$hivepath" Scripts/Disable_Internal_Drives.reg
      if [[ ! $? -eq 0 ]]; then exit 1; fi
      echo "Remove the Windows Recovery Environment..."
      rm "/Volumes/UFD-Windows/$winrepath"
      exit 0
elif  [[ -e /dev/$drive && $system == "Linux" ]]; then
      if   [[ "$usezenity" == "true" && ! -t 0 ]]; then
           zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
           if [[ $? -ne 0 ]]; then exit 1; fi
      elif [[ "$usezenity" == "false" ]]; then
           echo "Reading device information..."
      fi
      sudo chmod o+rw /dev/$drive
      devblksz=$(blockdev --getss /dev/$drive)
      disk_length=$(sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}')
      mibblksz=$(($mbyte / $devblksz))
      disk_offset=$(($disk_length - $mibblksz))
      (
      echo "Unmount volumes..."
      umount /dev/$drive?
      if [[ "$usezenity" == "true" ]]; then echo "10"; printf "# "; fi
      echo "Erase MBR/GPT structures..."
      dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null #Wipe first two megabytes of disk.
      dd if=/dev/zero of=/dev/$drive bs=1M seek=351 count=1 2> /dev/null #Wipe start of Windows area.
      dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null #Wipe last megabyte of disk.
      if [[ "$usezenity" == "true" ]]; then echo "20"; printf "# "; fi
      echo "Prepare disk and make bootable..."
      if [[ "$usezenity" == "true" && ! -t 0 ]]; then
         zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
         if [[ $? -ne 0 ]]; then
	      echo "# Partitioning operation canceled."
              exit 1
	   fi
      fi
      echo -e ',350M,c,*\n,,7' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
      if [[ $verbose == "false" ]]; then dspmode="-q"; fi
      sudo chmod o+rw /dev/$drive"1"
      mkftargs=(-F 32 -n "UFD-SYSTEM")
      if [[ $fmtyp == "FULL" ]]; then
         if [[ "$usezenity" == "true" ]]; then echo "25"; printf "# "; fi
         echo "Writing zeros to the system volume..."
         dd if=/dev/zero of=/dev/$drive"1" bs=1M status=none 2> /dev/null
         if [[ "$usezenity" == "true" ]]; then echo "30"; printf "# "; fi
         echo "Checking system volume for bad blocks..."
         mkftargs+=(-c)
      fi
      if   [[ $verbose == "true" ]]; then
           if [[ $fmtyp == "QUICK" ]]; then
	      echo "Creating FAT32 file system on system volume..."
	   fi
           mkftargs+=($dspmode)
           echo $boarder
           mkfs.fat "${mkftargs[@]}" /dev/$drive"1" | \
           if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
           echo $boarder
      else
           mkfs.fat "${mkftargs[@]}" /dev/$drive"1" > /dev/null
      fi
      sudo chmod o+rw /dev/$drive"2"
      volume_size=$(blockdev --getsize64 /dev/$drive"2")
      mkntargs=($dspmode -L "UFD-Windows")
      if [[ $fmtyp == "QUICK" ]]; then mkntargs+=(-Q); fi
      if [[ ($fmtyp == "FULL" && "$usezenity" == "true") ||
            ($fmtyp == "QUICK" && $verbose == "true") ]]; then
         if [[ "$usezenity" == "true" && $fmtyp == "FULL" ]]; then echo "35"; printf "# "; fi
         echo "Creating NTFS file system on Windows volume..."
      fi
      if   [[ $fmtyp == "FULL" && $verbose == "true" ]]; then
           sedfmtcmds="s/Initializing device with zeroes.*Done\.//;/^$/d"
           coproc BUFF (mkntfs "${mkntargs[@]}" /dev/$drive"2") &> "$vbfmtinfo"
      else
           coproc BUFF (mkntfs "${mkntargs[@]}" /dev/$drive"2") 2>&1
      fi
      if [[ $fmtyp == "FULL" ]]; then show_progress; fi
      if [[ $verbose == "true" ]]; then display_verbose; fi
      if [[ $fmtyp == "QUICK" && $verbose == "false" ]]; then wait $BUFF_PID; fi
      if [[ "$biosmode" == "true" ]]; then
         ms-sys -7 /dev/$drive > /dev/null && sleep 1
         ms-sys -8 /dev/$drive"1" > /dev/null && sleep 1
      fi
      if [[ "$usezenity" == "true" ]]; then
         echo "40"; echo "# Applying image to partition..."
      fi
      wimapply "$wimfile" $image /dev/$drive"2" 2> /tmp/wimfile_errors.txt
      if [[ $? -ne 0 ]]; then
         if   [[ "$usezenity" == "true" ]]; then
              errmsg=$(cat /tmp/wimfile_errors.txt)
              echo "# Unable to apply image!"
              zenity --error --title="Imaging Failure" --text="$errmsg" 2> /dev/null
         else
              cat /tmp/wimfile_errors.txt
         fi
         exit 1
      fi
      if [[ "$usezenity" == "true" ]]; then echo "60"; printf "# "; fi
      echo "Mount the partitions..."
      gio mount -d /dev/$drive"1"
      gio mount -d /dev/$drive"2"
      sysmount=$(lsblk -n -o MOUNTPOINT /dev/$drive"1")
      winmount=$(lsblk -n -o MOUNTPOINT /dev/$drive"2")
      if [[ "$usezenity" == "true" ]]; then echo "70"; printf "# "; fi
      echo "Setup the Windows boot files..."
      bcdargs=("-f" "both" "$winmount" "-s" "$sysmount" "-n" "$prodname")
      if   [[ "$usezenity" == "true" ]]; then
           zenity --password --title="Password Authentication" | sudo -Sv
           errmsg=$(bcd-sys "${bcdargs[@]}")
      else
           bcd-sys "${bcdargs[@]}"
      fi
      if   [[ ! $? -eq 0 ]]; then
           if [[ "$usezenity" == "true" ]]; then
              echo "# Unable to create boot files!"
              zenity --error --title="BCD-SYS Failure" --text="$errmsg" 2> /dev/null
           fi
           exit 1
      fi
      if [[ "$usezenity" == "true" ]]; then echo "75"; printf "# "; fi
      echo "Set internal disks to offline..."
      if   [[ "$usezenity" == "true" ]]; then
           errmsg=$(hivexregedit --merge --prefix SYSTEM "$winmount/$hivepath" Scripts/Disable_Internal_Drives.reg 2>&1) 
      else
           hivexregedit --merge --prefix SYSTEM "$winmount/$hivepath" Scripts/Disable_Internal_Drives.reg
      fi
      if [[ ! $? -eq 0 ]]; then
         if [[ "$usezenity" == "true" ]]; then
            echo "# Unable to apply registry policy!"
            zenity --error --title="Registry Update Failure" --text="$errmsg" 2> /dev/null
         fi
         exit 1
      fi
      if [[ "$usezenity" == "true" ]]; then echo "80"; printf "# "; fi
      echo "Remove the Windows Recovery Environment..."
      rm "$winmount/$winrepath"
      if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
      echo "Flush device write buffer..."
      sudo blockdev --flushbufs /dev/$drive"1"
      sudo blockdev --flushbufs /dev/$drive"2"
      if [[ "$usezenity" == "true" ]]; then echo "100"; echo "# Finished!"; fi
      ) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
      exit 0
else
      if   [[ "$usezenity" == "true" ]]; then
           zenity --error --title="Device Error" --text="Unable to access disk: $drive."
      else
           echo "Unable to access drive:" $drive
      fi
      exit 1
fi
