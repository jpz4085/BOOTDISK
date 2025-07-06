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
biosmode="false"

if [[ $prtshm == "MBR" ]]; then
   if [[ $fstyp == "FAT32" ]]; then pty=c; fi                      #FAT32 LBA
   if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]]; then pty=7; fi  #NTFS/HPFS/exFAT
   if [[ ! -z $(command -v ms-sys) ]]; then biosmode="true"; fi    #Legacy bootable.
fi
if [[ $prtshm == "GPT" ]]; then
   pty="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"   #Microsoft basic data
fi

ignore_btn="osascript ../Support/click_ignore.scpt" #Close macOS disk warning dialogue.

# Verify selected ISO file then check size of install archive.
if  [[ "$isofile" == *".iso"* && ! -e "$isofile" ]]; then
    echo "Unable to access Windows ISO file."
    echo
    read -p "Press any key to continue... " -n1 -s
    exit 1
fi
if  [[ "$isofile" == *".iso"* ]]; then
    wimext="wim" # Extention will be renamed if using wimsplit.
    wimsize=$(7z l "$isofile" | grep install.wim | awk '{print $4}')
    if  [[ "$fstyp" == "FAT32" && $wimsize -gt 4294967296 ]]; then
        if  [[ $wimtools == "true" ]]; then
            wimext="swm"
        else
            echo "FAT32 is not compatible with files larger than 4GBs."
            echo "Please install wimlib or format disk as NTFS or EXFAT."
            echo
            read -p "Press any key to continue... " -n1 -s
            exit 1
        fi
    fi
fi

# Verify selected disk and run requested actions.
if	[[ -e /dev/$drive && $system == "Darwin" ]]; then
	echo "Erase selected flash drive..."
	if   [[ $prtshm == "MBR" ]]; then
	     diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
	elif [[ $prtshm == "GPT" ]]; then
	     diskutil eraseDisk "Free Space" %noformat% GPT $drive > /dev/null
	fi
	echo "Prepare disk and make bootable (sudo required)..."
	sudo chmod o+rw /dev/'r'$drive && sudo chmod o+rw /dev/$drive
	disk_length=`diskutil info $drive | grep "Disk Size:" | awk '{print $8}'`
	if   [[ $uefint == "Y" ]]; then
	     if   [[ $prtshm == "MBR" ]]; then
	          printf 'e 1\n'$pty'\n\n2048\n'$(($disk_length - 4096))'\nf 1\ne 2\n1\n\n\n\nq\n' | \
	          fdisk -u -f Sectors/mswinmbr.bin -y -e /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	          Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
	     elif [[ $prtshm == "GPT" ]]; then
	          if  [[ -e /usr/local/bin/sgdisk ]]; then
	              sgdisk -o /dev/'r'$drive > /dev/null 2>&1
	              sgdisk -n 0:0:-4063 -t '0:'$pty -c 0:"$label" /dev/'r'$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
	              sgdisk -n 0:0:-2015 -t '0:'$pty -c 0:UEFI_NTFS /dev/'r'$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
	          else
	              gpt remove -a /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	              gpt add -b 2048 -s $(($disk_length - 6144)) -t $pty /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	              gpt add -s 2048 -t $pty /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	              gpt label -i 1 -l "$label" /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	              gpt label -i 2 -l UEFI_NTFS /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	          fi
	     fi
	     sudo chmod o+rw /dev/'r'$drive's2'
	     dd if=../Support/uefi-ntfs.img of=/dev/'r'$drive's2' 2> /dev/null
	else
	     if   [[ $prtshm == "MBR" ]]; then
	          printf 'e 1\n'$pty'\n\n2048\n\nf 1\nq\n' | \
	          fdisk -u -f Sectors/mswinmbr.bin -y -e /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	          Scripts/signmbr /dev/$drive > /dev/null && $ignore_btn &> /dev/null
	     elif [[ $prtshm == "GPT" ]]; then
	          if  [[ -e /usr/local/bin/sgdisk ]]; then
	              sgdisk -o /dev/'r'$drive > /dev/null 2>&1
	              sgdisk -n 0:0:-2015 -t '0:'$pty -c 0:"$label" /dev/'r'$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
	          else
	              gpt remove -a /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	              gpt add -b 2048 -s $(($disk_length - 4096)) -t $pty /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	              gpt label -i 1 -l "$label" /dev/'r'$drive > /dev/null && $ignore_btn &> /dev/null
	          fi
	     fi
	fi
	sudo chmod o+rw /dev/'r'$drive's1'
	if   [[ $fstyp == "FAT32" ]]; then
	     if  [[ $pty == "c" ]]; then
	         newfs_msdos -B Sectors/BOOTMGR/fat32pbr.bin -F 32 -v "$label" /dev/'r'$drive's1' > /dev/null
	         dd if=Sectors/BOOTMGR/fat32ebs.bin of=/dev/'r'$drive's1' bs=512 seek=12 count=1 2> /dev/null
	     else
	         newfs_msdos -F 32 -v "$label" /dev/'r'$drive's1' > /dev/null
	     fi
	elif [[ $fstyp == "EXFAT" ]]; then
	     newfs_exfat -v "$label" /dev/'r'$drive's1' > /dev/null
	     if [[ $pty == "7" ]]; then
	        sudo chmod o+rw /dev/$drive's1'
	        if  [[ ! -z $(command -v ms-sys) ]]; then
	            ms-sys -x /dev/$drive's1' > /dev/null
	        else
	            exfatboot -B Sectors/BOOTMGR/exfatpbr.bin /dev/$drive's1' > /dev/null
	        fi
	     fi
	elif [[ $fstyp == "NTFS" ]]; then
	     personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
	     if   [[ $personality == "Tuxera" ]]; then
	          sudo /usr/local/sbin/newfs_tuxera_ntfs -v "$label" /dev/$drive's1' > /dev/null
	          echo "18: 3F00" | sudo xxd -g 0 -r - /dev/$drive's1' #Set sectors per track to 63.
	          echo "1A: FF00" | sudo xxd -g 0 -r - /dev/$drive's1' #Set number of heads to 255.
	          if [[ $pty == "7" ]]; then
	             sudo chmod o+rw /dev/$drive's1'
	             if  [[ ! -z $(command -v ms-sys) ]]; then
	                 ms-sys -n /dev/$drive's1' > /dev/null
	             else
	                 dd if=Sectors/BOOTMGR/ntfspbr.bin of=/dev/$drive's1' bs=1 skip=84 seek=84 count=426 2> /dev/null
	                 dd if=Sectors/BOOTMGR/ntfsipl.bin of=/dev/$drive's1' seek=1 count=9 2> /dev/null
	             fi
	          fi
	     elif [[ $personality == "UFSD_NTFS" ]]; then
	          ufsd_path="/Library/Filesystems/ufsd_NTFS.fs/Contents/Resources"
	          sudo $ufsd_path/mkntfs -win7 -f -v:"$label" /dev/$drive's1' > /dev/null
	          echo "1C: 00080000" | sudo xxd -g 0 -r - /dev/$drive's1' #Set start sector to 2048.
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
	if [[ "$isofile" == *".iso"* ]]; then
 	   if   [[ "$fstyp" == "FAT32" && $wimsize -gt 4294967296 ]]; then
 	        echo "Extract Windows install files..."
	        7z x "$isofile" -xr\!install.wim -o/Volumes/"$label" > /dev/null
	        echo "Mount install disk image..."
	        hdiutil attach "$isofile" -mountpoint /tmp/isomount -nobrowse > /dev/null
	        echo "Split install archive for FAT32..."
	        wimsplit /tmp/isomount/sources/install.wim /Volumes/"$label"/sources/install.swm 3800 > /dev/null
	        echo "Unmount install disk image..."
	        hdiutil detach /tmp/isomount > /dev/null
	   else
	        echo "Extract Windows install files..."
	        7z x "$isofile" -o/Volumes/"$label" > /dev/null
	   fi
	   if [[ ! -e /Volumes/"$label"/efi/boot/bootx64.efi ]]; then
	      echo "Copy bootmgfw.efi to the EFI boot folder..." # This should only apply to Windows 7 media.
	      7z e /Volumes/"$label"/sources/install.$wimext Windows/Boot/EFI/bootmgfw.efi -o/Volumes/"$label"/efi/boot > /dev/null && \
	      mv /Volumes/"$label"/efi/boot/bootmgfw.efi /Volumes/"$label"/efi/boot/bootx64.efi
	   fi
	fi
	echo "Finished!"
	sleep 1
elif	[[ -e /dev/$drive && $system == "Linux" ]]; then
	echo "Unmount volumes..."
	umount /dev/$drive?
	echo "Erase MBR/GPT structures (sudo required)..."
	sudo chmod o+rw /dev/$drive
	disk_length=$(sfdisk -l /dev/$drive | grep "Disk /dev/$drive:" | awk '{print $7}')
	disk_offset=$(($disk_length - 4096))
	dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	echo "Prepare disk and make bootable..."
	if [[ $uefint == "Y" ]]; then
	   if   [[ $prtshm == "MBR" ]]; then
	        echo -e ','$(($disk_length - 4096))','$pty',*\n,,1' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	   elif [[ $prtshm == "GPT" ]]; then
	        echo -e 'size='$(($disk_length - 6144))',type='$pty',name="'"$label"'"\nsize=2048,type='$pty',name=UEFI_NTFS' | \
	        sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	   fi
	   sudo chmod o+rw /dev/$drive"2"
	   dd if=../Support/uefi-ntfs.img of=/dev/$drive"2" 2> /dev/null
	else
	   if   [[ $prtshm == "MBR" ]]; then
	        echo ',,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null
	   elif [[ $prtshm == "GPT" ]]; then
	        echo 'size='$(($disk_length - 4096))',type='$pty',name="'"$label"'"' | \
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
	echo "Mount boot disk..." && sleep 1
	gio mount -d /dev/$drive"1"
	if [[ "$isofile" == *".iso"* ]]; then
 	   if   [[ "$fstyp" == "FAT32" && $wimsize -gt 4294967296 ]]; then
 	        echo "Extract Windows install files..."
	        7z x "$isofile" -xr\!install.wim -o/media/$USER/"$label" > /dev/null
	        echo "Mount install disk image..."
	        sudo mkdir -p /mnt/isomount && sudo mount -o loop "$isofile" /mnt/isomount
	        echo "Split install archive for FAT32..."
	        wimsplit /mnt/isomount/sources/install.wim /media/$USER/"$label"/sources/install.swm 3800 > /dev/null
	        echo "Unmount install disk image..."
	        sudo umount /mnt/isomount && sudo rm -d /mnt/isomount
	   else
	        echo "Extract Windows install files..."
	        7z x "$isofile" -o/media/$USER/"$label" > /dev/null
	   fi
	   if [[ ! -e /media/$USER/"$label"/efi/boot/bootx64.efi ]]; then
	      echo "Copy bootmgfw.efi to the EFI boot folder..." # This should only apply to Windows 7 media.
	      7z e /media/$USER/"$label"/sources/install.$wimext Windows/Boot/EFI/bootmgfw.efi -o/media/$USER/"$label"/efi/boot > /dev/null && \
	      mv /media/$USER/"$label"/efi/boot/bootmgfw.efi /media/$USER/"$label"/efi/boot/bootx64.efi
	   fi
	   echo "Flush device write buffer..."
	   sudo blockdev --flushbufs /dev/$drive"1"
	fi
	echo "Finished!"
	sleep 1
else
	echo "Unable to access drive:" $drive
	echo
	read -p "Press any key to continue... " -n1 -s
	exit 1
fi
