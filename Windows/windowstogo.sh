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
hivepath="Windows/System32/config/SYSTEM"
winrepath="Windows/System32/Recovery/Winre.wim"
prodname=$(wiminfo "$wimfile" $image | grep -m 1 Name: | sed "s/^.*: *//" | awk '{printf ("%s %s", $1, $2)}')

if    [[ -e /dev/$drive && $system == "Darwin" ]]; then
      ignore_btn="osascript ../Support/click_ignore.scpt" #Ignore disk warnings.
      bcdargs=("-f" "both" "/Volumes/UFD-Windows" "-s" "/Volumes/UFD-SYSTEM" "-n" "$prodname")
      echo "Erase selected flash drive..."
      diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
      echo "Prepare disk and make bootable (sudo required)..."
      printf 'e 1\nc\n\n2048\n716800\nf 1\ne 2\n7\n\n\n\nq\n' | \
      sudo fdisk -u -f Sectors/mswinmbr.bin -y -e /dev/$drive > /dev/null && $ignore_btn &> /dev/null
      sudo Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
      sudo newfs_msdos -B Sectors/BOOTMGR/fat32pbr.bin -F 32 -v "UFD-SYSTEM" /dev/'r'$drive's1' > /dev/null
      sudo dd if=Sectors/BOOTMGR/fat32ebs.bin of=/dev/'r'$drive's1' bs=512 seek=12 count=1 2> /dev/null
      personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
      if   [[ $personality == "Tuxera" ]]; then
           sudo /usr/local/sbin/newfs_tuxera_ntfs -v "UFD-Windows" /dev/$drive's2' > /dev/null
           echo "18: 3F00" | sudo xxd -g 0 -r - /dev/$drive's2' #Set sectors per track to 63.
           echo "1A: FF00" | sudo xxd -g 0 -r - /dev/$drive's2' #Set number of heads to 255.
      elif [[ $personality == "UFSD_NTFS" ]]; then
           ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
           sudo $ufsd_path/mkntfs -win7 -f -v:"UFD-Windows" /dev/$drive's2' > /dev/null
           echo "1C: 00F80A00" | sudo xxd -g 0 -r - /dev/$drive's2' #Set start sector to 718,848.
      else
           sudo mkntfs -Q -L "UFD-Windows" -p 718848 -H 255 -S 63 /dev/$drive's2' > /dev/null
      fi
      sudo wimapply "$wimfile" $image /dev/$drive's2' 2> /tmp/wimfile_errors.txt
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
      disk_length=`sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}'`
      disk_offset=$(($disk_length - 4096))
      echo "Unmount volumes..."
      umount /dev/$drive?
      echo "Erase MBR/GPT structures..."
      dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
      dd if=/dev/zero of=/dev/$drive bs=1M seek=351 count=1 2> /dev/null
      dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
      echo "Prepare disk and make bootable (sudo required)..."
      echo -e ',716800,c,*\n,,7' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
      mkfs.fat -F 32 -n "UFD-SYSTEM" /dev/$drive"1" > /dev/null
      mkntfs -Q -L "UFD-Windows" /dev/$drive"2" > /dev/null
      if [[ ! -z $(command -v ms-sys) ]]; then
         ms-sys -7 /dev/$drive > /dev/null && sleep 1
         ms-sys -8 /dev/$drive"1" > /dev/null && sleep 1
      fi
      wimapply "$wimfile" $image /dev/$drive"2" 2> /tmp/wimfile_errors.txt
      if [[ ! $? -eq 0 ]]; then cat /tmp/wimfile_errors.txt; exit 1; fi
      echo "Mount the partitions..."
      gio mount -d /dev/$drive"1"
      gio mount -d /dev/$drive"2"
      sysmount=$(lsblk -n -o MOUNTPOINT /dev/$drive"1")
      winmount=$(lsblk -n -o MOUNTPOINT /dev/$drive"2")
      echo "Setup the Windows boot files..."
      bcdargs=("-f" "both" "$winmount" "-s" "$sysmount" "-n" "$prodname")
      bcd-sys "${bcdargs[@]}"
      if [[ ! $? -eq 0 ]]; then exit 1; fi
      echo "Set internal disks to offline..."
      hivexregedit --merge --prefix SYSTEM "$winmount/$hivepath" Scripts/Disable_Internal_Drives.reg
      if [[ ! $? -eq 0 ]]; then exit 1; fi
      echo "Remove the Windows Recovery Environment..."
      rm "$winmount/$winrepath"
      echo "Flush device write buffer..."
      sudo blockdev --flushbufs /dev/$drive"1"
      sudo blockdev --flushbufs /dev/$drive"2"
      exit 0
else
      echo "Unable to access drive:" $drive
      exit 1
fi
