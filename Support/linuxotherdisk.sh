#!/usr/bin/env bash
#
# Bootdisk - Linux and Other Script.
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
isofile="$2"
drive="$3"
prtshm="$4"
pstpart="$5"
fstyp="$6"
label="$7"
erase="false"
persist="false"
hasgrub="false"
usblabel="false"
overlay="false"
pupsave="false"
fatsz=${fstyp:3}

kbyte=1024
mbyte=1048576
gbyte=1073741824
tbyte=1099511627776

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ $prtshm == "MBR" ]]; then
   if [[ $fstyp == "FAT16" ]]; then pty=e; fi #FAT16 LBA
   if [[ $fstyp == "FAT32" ]]; then pty=c; fi #FAT32 LBA
   erase="true"
fi
if [[ $prtshm == "GPT" ]]; then
   pty="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" #Microsoft basic data
   if [[ ! -z $(7z l "$isofile" | grep "grub.cfg") ]]; then
      biospty="21686148-6449-6E6F-744E-656564454649" #GRUB bios boot
      hasgrub="true" #Create a bios boot partition for GRUB.
   fi
   erase="true"
fi
if [[ $prtshm == "ERASE" ]]; then erase="true"; fi    #Wipe disk and apply image.
if [[ $prtshm == "CURRENT" ]]; then erase="false"; fi #Just extract image to disk.

isolabel=$(file "$isofile" | awk -F"'" '{for (i=2; i<=NF; i+=2) print $i}')

if [[ "$pstpart" != "N/A" ]]; then
   persist="true"
   extlabel="writable"
   linuxpty="0FC63DAF-8483-4772-8E79-3D69D8477DE4" #Linux filesystem
   isoextsz=$(7z l "$isofile" | grep 'files,' | awk '{print $3}') #Size of ISO contents.
   if echo "$isolabel" | grep -qiE "d-live"; then extlabel="persistence"; fi
   if echo "$isolabel" | grep -qiE "CDROM"; then pupsave="true"; fi
fi

if echo "$isolabel" | grep -qiE "Fedora"; then
   label=$(echo "$label" | sed 's/ /-/') #Replace spaces with dashes.
   usblabel="true" #Update volume label in GRUB arguments.
   if [[ "$persist" == "true" ]]; then overlay="true"; fi #Create a persistent overlay image.
fi

unit_sizes () {
unitsz="$1"
case "${unitsz: -1}" in
      K)
      baseunit=$kbyte
      errunit=$baseunit
      errsym="K"
      ;;
      M)
      baseunit=$mbyte
      errunit=$baseunit
      errsym="K"
      ;;
      G)
      baseunit=$gbyte
      errunit=$mbyte
      errsym="M"
      ;;
      T)
      baseunit=$tbyte
      errunit=$gbyte
      errsym="G"
      ;;
esac
}

apply_image () {
echo "Applying image to disk..."
dd if="$1" of=/dev/"$2" bs="$3" conv=fsync oflag=direct status=none
echo "Finished!" && sleep 2
exit 0
}

extract_files () {
echo "Extract files to disk..."
7z x "$1" -y -o"$2" > /dev/null
}

config_persist () {

i=0
pstarg="persistent"
pstname="$pstarg"
pstconf="false"
configs=()
schterms=("/casper/vmlinuz" "/live/vmlinuz" "boot=casper" "rd.live.image")

while [[ -z "${configs[@]}" ]]; do
      readarray -t configs <<< $(grep -r -m 1 --exclude-dir='.*' --include=\*.cfg "${schterms[$i]}" "$1" | awk -F: '{print $1}')
      if [[ ! -z "${configs[@]}" ]]; then
         if   [[ "${schterms[$i]}" == "/live/vmlinuz" ]]; then
              pstarg="persistence"
              pstname="$pstarg"
              if [[ $system == "Linux" ]]; then pstconf="true"; fi
              if [[ $system == "Darwin" ]]; then pstconf="alert"; fi
         elif [[ "${schterms[$i]}" == "rd.live.image" ]]; then
              pstarg="rd.live.overlay=LABEL=$extlabel:fedora-live.img"
              pstname="rd.live.overlay"
         fi
      fi
      ((i++)) #Next search term
done

for key in "${!configs[@]}"
do
    if   [[ $overlay == "true" ]]; then
         lnum_vmlz=$(grep -nwi -m 1 "${configs[$key]}" -e 'rd.live.image' | awk -F: '{print $1}')
    else
	     lnum_vmlz=$(grep -nwi -m 1 "${configs[$key]}" -e 'vmlinuz' | awk -F: '{print $1}')
    fi
    lnum_appnd=$(grep -nwi -m 1 "${configs[$key]}" -e 'append' | awk -F: '{print $1}')
    if   [[ ! -z "$lnum_appnd" ]]; then
         echo "Add $pstname option to $(basename "${configs[$key]}")"
         if   [[ $system == "Darwin" ]]; then
              sed -i '' "$lnum_appnd""s/$/ $pstarg/" "${configs[$key]}"
         elif [[ $system == "Linux" ]]; then
              sed -i "$lnum_appnd""s/$/ $pstarg/" "${configs[$key]}"
         fi
    else
         echo "Add $pstname option to $(basename "${configs[$key]}")"
         if   [[ $system == "Darwin" ]]; then
              sed -i '' "$lnum_vmlz""s/$/ $pstarg/" "${configs[$key]}"
         elif [[ $system == "Linux" ]]; then
              sed -i "$lnum_vmlz""s/$/ $pstarg/" "${configs[$key]}"
         fi
    fi
done
if   [[ "$pstconf" == "true" ]]; then
     echo "/ union" | sudo tee "$2"/persistence.conf > /dev/null
elif [[ "$pstconf" == "alert" ]]; then
     echo -e "${YELLOW}Create a 'persistence.conf' file on the Linux volume.${NC}"
     echo -e "${YELLOW}See the Debian section of the About menu for details.${NC}"
fi

if [[ $overlay == "true" ]]; then
   if   [[ $system == "Linux" ]]; then
        volfreeblks=$(df -BM --output=avail "$2" | grep 'M' | sed 's/M//')
   elif [[ $system == "Darwin" ]]; then
        volfreebytes=$(diskutil info "$2" | grep "Volume Free Space:" | awk '{print $6}' | sed 's/(//')
        volfreeblks=$(($volfreebytes / $mbyte))
   fi
   echo "Creating persistent overlay image..."
   sudo dd if=/dev/zero of="$2"/fedora-live.img bs="$3" count=$volfreeblks status=none
   echo "Formatting persistent overlay image..."
   sudo mkfs.ext4 -q -L persistence "$2"/fedora-live.img > /dev/null
   if   [[ $system == "Linux" ]]; then
        echo "Creating folders on the persistent image..."
        imgblkdev=$(sudo losetup --find --show "$2"/fedora-live.img)
        sleep 3 && gio mount -d "$imgblkdev"
        overlay_folder="/media/$USER/persistence/overlayfs"
        ovlwork_folder="/media/$USER/persistence/ovlwork"
        sudo mkdir -m 0755 "$overlay_folder" "$ovlwork_folder"
        sudo setfattr -n security.selinux -v "system_u:object_r:root_t:s0" "$overlay_folder" "$ovlwork_folder"
        umount "$imgblkdev" && sudo losetup -d "$imgblkdev"
   elif [[ $system == "Darwin" ]]; then
        echo -e "${YELLOW}Create the required folders on the persistent image.${NC}"
        echo -e "${YELLOW}See the Fedora section of the About menu for details.${NC}"
   fi
fi
}

rename_isolinux () {
if mv "$1"/isolinux "$1"/syslinux 2> /dev/null; then
   echo "Rename isolinux files to syslinux..."
   mv "$1"/syslinux/isolinux.bin "$1"/syslinux/syslinux.bin
   mv "$1"/syslinux/isolinux.cfg "$1"/syslinux/syslinux.cfg
fi
}

update_cdlabel () {
config=$(grep -r -m 1 --exclude-dir='.*' --include=\grub.cfg 'rd.live.image' "$1" | awk -F: '{print $1}')
echo "Update $(basename "$config") with new volume label..."
if   [[ $system == "Darwin" ]]; then
     sed -i '' "s/default=\"1\"/default=\"0\"/" "$config"
     sed -i '' "s/$isolabel/$label/g" "$config"
elif [[ $system == "Linux" ]]; then
     sed -i "s/default=\"1\"/default=\"0\"/" "$config"
     sed -i "s/$isolabel/$label/g" "$config"
fi
}

# Verify selected drive is valid and run actions.

if    [[ $erase == "true" && -e /dev/$drive ]]; then
      if [[ $system == "Darwin" ]]; then
         ignore_btn="osascript ./click_ignore.scpt" #Close macOS disk warning dialogue.
         devblksz=$(diskutil info $drive | grep 'Device Block Size:' | awk '{print $4}')
         disk_length=$(diskutil info $drive | grep "Disk Size:" | awk '{print $8}')
         disk_size=$(diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-)
         if [[ $fstyp == "FAT16" && $disk_size -ge $(($gbyte * 2)) ]]; then
            echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
            echo
            read -p "Press any key to continue... " -n1 -s
            exit 1
         fi
         if [[ "$persist" == "true" ]]; then
            isoblksz=$(stat -f %b "$isofile")
            isobytesz=$(stat -f %z "$isofile")
            if [[ $isoextsz -gt $isobytesz ]]; then
               isobytesz=$isoextsz
               isoblksz=$(($isoextsz / $devblksz))
            fi
            isomibsz=$(($isobytesz / $mbyte))
            isoblkpad=$((($mbyte * 50) / $devblksz))
            isomibpad=$((($mbyte * 50) / $mbyte))
            if [[ "$pstpart" != "deferred" && "$pstpart" != "END" ]]; then
               unit_sizes "$pstpart"
               lnxpartszbytes=$((${pstpart%?} * $baseunit))
               lnxpartlenblks=$(($lnxpartszbytes / $devblksz))
               usedbytes=$(($isobytesz + ($mbyte * 50)))
               freebytes=$(($disk_size - $usedbytes))
               if [[ $lnxpartszbytes -ge $freebytes ]]; then
                  available=$(($freebytes / $errunit))
                  echo -e "${YELLOW}Insufficient free space for persistent partition.${NC}"
                  echo "Please specifiy a maximum size of up to $available$errsym."
                  echo
                  read -p "Press any key to continue... " -n1 -s
                  exit 1
               fi
            fi
         fi
         if [[ $prtshm == "ERASE" ]]; then
            mibblksz=$(($mbyte / $devblksz))
            disk_offset=$(($disk_length - $mibblksz))
            echo "Unmount volumes..."
            diskutil unmountDisk $drive > /dev/null
            echo "Erase MBR/GPT structures (sudo required)..."
            sudo chmod o+rw /dev/$drive
            dd if=/dev/zero of=/dev/$drive bs=1m count=2 2> /dev/null
            dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
            apply_image "$isofile" "$drive" "4m"
         fi
         echo "Partition and format disk (sudo required)..."
         hds=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f2 -d"/")
         spt=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f3 -d"/")
         if   [[ $prtshm == "MBR" ]]; then
              diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
              sudo chmod o+rw /dev/$drive
              if   [[ "$persist" == "true" ]]; then
                   if   [[ "$pstpart" == "deferred" ]]; then
                        printf 'e 1\n'$pty'\n\n\n'$(($isoblksz + $isoblkpad))'\nf 1\nq\n' | \
                        fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
                   else
                        lnxpartlenblks+="\n"
                        if [[ "$overlay" == "true" ]]; then pstprtyp=7; else pstprtyp=83; fi
                        printf 'e 1\n'$pty'\n\n\n'$(($isoblksz + $isoblkpad))'\nf 1\ne 2\n'$pstprtyp'\n\n\n'$lnxpartlenblks'q\n' | \
                        fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
                   fi
              else
                   printf 'e 1\n'$pty'\n\n\n\nf 1\nq\n' | fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
              fi
         elif [[ $prtshm == "GPT" ]]; then
              if   [[ ! -z $(command -v sgdisk) ]]; then
                   diskutil eraseDisk -noEFI "Free Space" %noformat% GPT $drive > /dev/null
                   sudo chmod o+rw /dev/$drive
                   sgdisk -o /dev/$drive > /dev/null 2>&1
                   if [[ $hasgrub == "true" ]]; then
                      sgdisk -n 0:0:+1M -t '0:EF02' -c 0:"GRUB BIOS" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                   fi
                   if   [[ "$persist" == "true" ]]; then
                        sgdisk -n 0:0:$(($isoblksz + $isoblkpad)) -t '0:0700' -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                        if [[ "$pstpart" != "deferred" ]]; then
                           if   [[ $pstpart == "END" ]]; then
                                pstpartblks="0"
                           else
                                pstpartblks="+$pstpart"
                           fi
                           if [[ "$overlay" == "true" ]]; then pstprtyp="0700"; else pstprtyp="8300"; fi
                           sgdisk -n 0:0:$pstpartblks -t 0:$pstprtyp -c 0:$extlabel /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                        fi
                   else
                        sgdisk -n 0:0:0 -t '0:0700' -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                   fi
              else
                   if [[ $hasgrub == "true" ]]; then
                      diskargs=(%$biospty% %noformat% 1MiB )
                   fi
                   if   [[ "$persist" == "true" ]]; then
                        diskargs+=(%$pty% %noformat% $(($isomibsz + $isomibpad))MiB )
                        if   [[ "$pstpart" == "deferred" ]]; then
                             diskargs+=("Free Space" %noformat% R)
                             diskutil partitionDisk -noEFI $drive 3 GPT "${diskargs[@]}" > /dev/null
                        else
                             if   [[ $pstpart == "END" ]]; then
                                  if [[ "$overlay" == "true" ]]; then pstprtyp="$pty"; else pstprtyp="$linuxpty"; fi
                                  diskargs+=(%$pstprtyp% %noformat% R)
                                  diskutil partitionDisk -noEFI $drive 3 GPT "${diskargs[@]}" > /dev/null
                             else
                                  if [[ "$overlay" == "true" ]]; then pstprtyp="$pty"; else pstprtyp="$linuxpty"; fi
                                  diskargs+=(%$pstprtyp% %noformat% $pstpart )
                                  diskargs+=("Free Space" %noformat% R)
                                  diskutil partitionDisk -noEFI $drive 4 GPT "${diskargs[@]}" > /dev/null
                             fi
                        fi
                   else
                        if   [[ $hasgrub == "true" ]]; then
                             diskargs+=(%$pty% %noformat% R)
                             diskutil partitionDisk -noEFI $drive 2 GPT "${diskargs[@]}" > /dev/null
                        else
                             diskutil eraseDisk -noEFI FAT32 %noformat% GPT $drive > /dev/null
                        fi
                   fi
              fi
         fi
         if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
         sudo newfs_msdos -u $spt -h $hds -F $fatsz -v "$label" /dev/$drive's'$isopart > /dev/null
         if [[ "$persist" == "true" ]]; then
            if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
            if   [[ "$overlay" == "true" ]]; then
                 sudo newfs_exfat -v $extlabel /dev/$drive's'$extpart > /dev/null
            else
                 sudo mkfs.ext4 -q -L $extlabel /dev/$drive's'$extpart > /dev/null
           fi
         fi
         echo "Mount boot disk..."
         if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
         diskutil mount $drive's'$isopart > /dev/null
         if [[ "$overlay" == "true" ]]; then
            if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
            diskutil mount $drive's'$extpart > /dev/null
         fi
         echo "Disable Spotlight indexing..."
         mdutil -d /Volumes/"$label" &> /dev/null
         if [[ "$overlay" == "true" ]]; then
            mdutil -d /Volumes/"$extlabel" &> /dev/null
         fi
         extract_files "$isofile" /Volumes/"$label"
         if [[ -d /Volumes/"$label"/isolinux ]]; then
            rename_isolinux /Volumes/"$label"
         fi
         if [[ "$usblabel" == "true" ]]; then
            update_cdlabel /Volumes/"$label"
         fi
         if [[ "$persist" == "true" ]]; then
            if  [[ "$pupsave" == "true" ]]; then
                echo "SS_ID=$extlabel" | sudo tee /Volumes/"$label"/SAVESPEC > /dev/null
            else
                config_persist /Volumes/"$label" /Volumes/"$extlabel" "1m"
            fi
         fi
         if [[ -f /Volumes/"$label"/md5sum.txt ]]; then
            if   [[ "$persist" == "true" ]]; then
                 cd /Volumes/"$label"
                 rm md5sum.txt
                 echo "Create new md5sum.txt file..."
                 find . -type f -not -name 'md5sum.txt' -not -path "./\[BOOT\]*" -exec md5sum '{}' \; 2> /dev/null > md5sum.txt
            elif grep -q "isolinux" /Volumes/"$label"/md5sum.txt; then
                 echo "Update md5sum.txt file..."
                 sed -i '' 's/isolinux/syslinux/g' /Volumes/"$label"/md5sum.txt
            fi
         fi
         read -p "Finished! Press any key to exit." -n1 -s
         exit 0
      fi
      if  [[ $system == "Linux" ]]; then
          echo "Reading device information (sudo required)..."
          sudo chmod o+rw /dev/$drive
          devblksz=$(blockdev --getss /dev/$drive)
          disk_size=$(blockdev --getsize64 /dev/$drive)
          disk_length=$(sfdisk -l /dev/$drive 2> /dev/null | grep "Disk /dev/$drive:" | awk '{print $7}')
          mibblksz=$(($mbyte / $devblksz))
          disk_offset=$(($disk_length - $mibblksz))
	  
	  if [[ $fstyp == "FAT16" && $disk_size -ge $(($gbyte * 2)) ]]; then
	     echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
	     echo
	     read -p "Press any key to continue... " -n1 -s
	     exit 1
	  fi

	  if [[ "$persist" == "true" ]]; then
	     isoblksz=$(stat -c %b "$isofile")
	     isobytesz=$(stat -c %s "$isofile")
	     if [[ $isoextsz -gt $isobytesz ]]; then
	       isobytesz=$isoextsz
	       isoblksz=$(($isoextsz / $devblksz))
	     fi
	     isoblkpad=$((($mbyte * 50) / $devblksz))
	     if [[ "$pstpart" != "+" ]]; then
                unit_sizes "$pstpart"
                lnxpartszbytes=$((${pstpart%?} * $baseunit))
                lnxpartlenblks=$(($lnxpartszbytes / $devblksz))
                usedbytes=$(($isobytesz + ($mbyte * 50)))
                freebytes=$(($disk_size - $usedbytes))
                if [[ $lnxpartszbytes -ge $freebytes ]]; then
                   available=$(($freebytes / $errunit))
                   echo -e "${YELLOW}Insufficient free space for persistent partition.${NC}"
                   echo "Please specifiy a maximum size of up to $available$errsym."
                   echo
                   read -p "Press any key to continue... " -n1 -s
                   exit 1
                fi
             fi
	  fi

	  echo "Unmount volumes..."
	  umount /dev/$drive?
	  echo "Erase MBR/GPT structures..."
	  dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	  dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	  if   [[ $prtshm == "ERASE" ]]; then
	       apply_image "$isofile" "$drive" "4M"
	  fi
	  echo "Partition and format disk..."
	  if   [[ $prtshm == "MBR" ]]; then
	       if   [[ "$persist" == "true" ]]; then
	            echo -e ','$(($isoblksz + $isoblkpad))','$pty',*\n,'$pstpart',L' | \
	            sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	       else
	            echo ',,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	       fi
	  elif [[ $prtshm == "GPT" ]]; then
	       if [[ $hasgrub == "true" ]]; then
	          sfdargs=(size=1M,type=$biospty,name='"'GRUB BIOS'"'\\n)
	       fi
	       if   [[ "$persist" == "true" ]]; then
	            sfdargs+=(size=$(($isoblksz + $isoblkpad)),type=$pty,name='"'$label'"'\\n)
	            sfdargs+=(size=$pstpart,type=L,name='"'$extlabel'"')
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       else
	            sfdargs+=(type=$pty,name='"'$label'"')
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       fi
	  fi
	  if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
	  sudo mkfs.fat -F $fatsz -n "$label" /dev/$drive"$isopart" > /dev/null
	  if [[ "$persist" == "true" ]]; then
	     if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
	     sudo mkfs.ext4 -q -L "$extlabel" /dev/$drive"$extpart" > /dev/null
	  fi
	  echo "Mount boot disk..." && sleep 1
	  if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
	  gio mount -d /dev/$drive"$isopart"
	  if [[ "$persist" == "true" ]]; then
	     if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
	     gio mount -d /dev/$drive"$extpart"
	  fi
	  extract_files "$isofile" /media/$USER/"$label"
	  if [[ -d /media/$USER/"$label"/isolinux ]]; then
	     rename_isolinux /media/$USER/"$label"
	  fi
	  if [[ "$usblabel" == "true" ]]; then
	     update_cdlabel /media/$USER/"$label"
	  fi
	  if [[ "$persist" == "true" ]]; then
	     if  [[ "$pupsave" == "true" ]]; then
                 echo "SS_ID=$extlabel" | sudo tee /media/$USER/"$label"/SAVESPEC > /dev/null
             else
                 config_persist /media/$USER/"$label" /media/$USER/"$extlabel" "1M"
             fi
	  fi
	  if [[ -f /media/$USER/"$label"/md5sum.txt ]]; then
	     if   [[ "$persist" == "true" ]]; then
	          cd /media/$USER/"$label"
	          rm md5sum.txt
	          echo "Create new md5sum.txt file..."
	          find -type f -not -name 'md5sum.txt' -not -path "./\[BOOT\]*" -exec md5sum '{}' \; > md5sum.txt
	     elif grep -q "isolinux" /media/$USER/"$label"/md5sum.txt; then
	          echo "Update md5sum.txt file..."
	          sed -i 's/isolinux/syslinux/g' /media/$USER/"$label"/md5sum.txt
	     fi
	  fi
	  read -p "Finished! Press any key to exit." -n1 -s
	  exit 0
      fi
elif  [[ $erase == "false" && -e "$drive" ]]; then
      extract_files "$isofile" "$drive"
      echo "Finished!" && sleep 1
else
      echo "Unable to access:" $drive
      echo
      read -p "Press any key to continue... " -n1 -s
      exit 1
fi
