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
image="$3"
drive="$4"
usegui="$5"
mbyte=1048576
biosmode="false"
hivepath="Windows/System32/config/SYSTEM"
winrepath="Windows/System32/Recovery/Winre.wim"
prodname=$(wiminfo "$wimfile" $image | grep -m 1 Name: | sed "s/^.*: *//" | awk '{printf ("%s %s", $1, $2)}')

if [[ ! -z $(command -v ms-sys) ]]; then biosmode="true"; fi #Legacy bootable.

if  [[ "$usegui" == "true" ]]; then
    usezenity="true"
    zenprogargs='--progress --no-cancel --title="BOOTDISK: Windows To Go"'
else
    usezenity="false"
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
      printf 'e 1\nc\n\n'$mibblksz'\n'$syspartsz'\nf 1\ne 2\n7\n\n\n'$winpartsz'\nq\n' | \
      fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
      Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
      if [[ "$biosmode" == "true" ]]; then
         ms-sys -7 /dev/$drive > /dev/null && $ignore_btn &> /dev/null
      fi
      sudo chmod o+rw /dev/$drive's1' /dev/$drive's2'
      newfs_msdos -u $spt -h $hds -F 32 -v "UFD-SYSTEM" /dev/$drive's1' > /dev/null
      if [[ "$biosmode" == "true" ]]; then
         ms-sys -8 /dev/$drive's1' > /dev/null
      fi
      personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
      if   [[ $personality == "Tuxera" ]]; then
           spthex=$(endian $(printf '%04X' $spt))
           hdshex=$(endian $(printf '%04X' $hds))
           /usr/local/sbin/newfs_tuxera_ntfs -v "UFD-Windows" /dev/$drive's2' > /dev/null
           echo "18: $spthex" | xxd -g 0 -r - /dev/$drive's2' #Set sectors per track per fdisk.
           echo "1A: $hdshex" | xxd -g 0 -r - /dev/$drive's2' #Set number of heads per fdisk.
      elif [[ $personality == "UFSD_NTFS" ]]; then
           winparthex=$(endian $(printf '%08X' $winpartsect))
           ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
           $ufsd_path/mkntfs -win7 -f -v:"UFD-Windows" /dev/$drive's2' > /dev/null
           echo "1C: $winparthex" | xxd -g 0 -r - /dev/$drive's2' #Set start sector to (351MiB) offset.
      else
           mkntfs -Q -L "UFD-Windows" -p $winpartsect -H $hds -S $spt /dev/$drive's2' > /dev/null
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
      if [[ "$usezenity" == "false" ]]; then
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
      dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
      dd if=/dev/zero of=/dev/$drive bs=1M seek=351 count=1 2> /dev/null
      dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
      if [[ "$usezenity" == "true" ]]; then echo "20"; printf "# "; fi
      echo "Prepare disk and make bootable..."
      echo -e ',350M,c,*\n,,7' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
      sudo chmod o+rw /dev/$drive"1"
      mkfs.fat -F 32 -n "UFD-SYSTEM" /dev/$drive"1" > /dev/null
      sudo chmod o+rw /dev/$drive"2"
      mkntfs -Q -L "UFD-Windows" /dev/$drive"2" > /dev/null
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
