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
datapart="$6"
fstyp="$7"
label="$8"
usegui="$9"
erase="false"
persist="false"
hasgrub="false"
usblabel="false"
overlay="false"
pupsave="false"
pipeview="false"
fatsz=${fstyp:3}

kbyte=1024
mbyte=1048576
gbyte=1073741824
tbyte=1099511627776

datapartsz=0

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if  [[ "$usegui" == "true" ]]; then
    usezenity="true"
    zenprogargs='--width=300 --progress --no-cancel --title="BOOTDISK: Linux/Other"'
else
    usezenity="false"
fi

if [[ ! -z $(command -v pv) ]]; then pipeview="true"; fi

if [[ $prtshm == "MBR" ]]; then
   if [[ $fstyp == "FAT16" ]]; then pty=e; fi #FAT16 LBA
   if [[ $fstyp == "FAT32" ]]; then pty=c; fi #FAT32 LBA
   if [[ $fstyp == "EXFAT" ]]; then pty=7; fi #NTFS/exFAT
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
if [[ $prtshm == "ERASE" ]]; then
   erase="true"                         #Wipe disk and apply image.
   if [[ $pipeview == "false" ]]; then
      zenprogargs+=' --pulsate'         #No progress bar without pipeviewer.
   fi
fi
if [[ $prtshm == "CURRENT" ]]; then
   erase="false"                      #Just extract image to disk.
fi

isolabel=$(file "$isofile" | awk -F"'" '{for (i=2; i<=NF; i+=2) print $i}')
isoextsz=$(7z l "$isofile" | grep 'files,' | awk '{print $3}') #Size of ISO contents.
isoimgsz=$(7z l "$isofile" \[BOOT\]/2-Boot-NoEmul.img | grep 'files' | awk '{print $1}') #Size of ISO boot image.

if [[ "$pstpart" != "N/A" ]]; then
   persist="true"
   mkexfat="false"
   extlabel="writable"
   linuxpty="0FC63DAF-8483-4772-8E79-3D69D8477DE4" #Linux filesystem
   if echo "$isolabel" | grep -qiE "d-live"; then extlabel="persistence"; fi
   if echo "$isolabel" | grep -qiE "CDROM"; then pupsave="true"; fi
   if [[ "$datapart" == "true" && ! -z $(command -v mkfs.exfat) ]]; then mkexfat="true"; fi
fi

if echo "$isolabel" | grep -qiE "Fedora|gentoo"; then
   label=$(echo "$label" | sed 's/ /-/') #Replace spaces with dashes.
   usblabel="true" #Update volume label in GRUB arguments.
   if [[ "$persist" == "true" ]]; then overlay="true"; fi #Create a persistent overlay image.
fi

if echo "$isolabel" | grep -qiE "MX-Live"; then
   efigrubcfg="boot/grub/config/efi-grub.cfg"
   efigrubmod="boot/grub/x86_64-efi/exfat.mod"
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
      errsym="M"
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
ddargs="conv=fsync oflag=direct status=none"
if [[ "$usezenity" == "true" ]]; then printf "# "; fi
if   [[ $pipeview == "true" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          echo "Applying image to disk..."
          (pv -n "$1" | dd of=/dev/"$2" bs="$3" $ddargs) 2>&1
     else
          pv -N 'Applying image to disk' -peb "$1" | dd of=/dev/"$2" bs="$3" $ddargs
     fi
else
     echo "Applying image to disk..."
     dd if="$1" of=/dev/"$2" bs="$3" $ddargs
fi
if [[ "$usezenity" == "true" ]]; then printf "# "; fi
echo "Finished!"
return 0
}

extract_files () {
isopct=0
valpct="$3"
divpct="$4"
if   [[ $system == "Darwin" ]]; then
     fsavail=$(df -k "$2" | awk '{print $4}' | tail -1)
elif [[ $system == "Linux" ]]; then
     bufpct=0
     fsavail=$(df --output=avail "$2" | tail -1)
fi
fsbegin=$(($fsavail * $kbyte))
isoextsz=$(($isoextsz - $isoimgsz))

coproc XISO (7z x "$1" -y -xr\!\[BOOT\] -o"$2" > /dev/null)

while kill -0 $XISO_PID 2> /dev/null; do
      if   [[ $system == "Darwin" ]]; then
           fsavail=$(df -k "$2" | awk '{print $4}' | tail -1)
      elif [[ $system == "Linux" ]]; then
           fsavail=$(df --output=avail "$2" | tail -1)
      fi
      if [[ "$usezenity" == "true" ]]; then echo "# Extracting ISO archive..."; fi
      isopct=$(((($fsbegin - ($fsavail * $kbyte)) * 100) / $isoextsz))
      if   [[ "$usezenity" == "true" ]]; then
           if   [[ $isopct -eq 100 && "$erase" == "false" ]]; then
                isoout=99
           else
                if   [ $divpct -gt 1 ]; then
                     isoout=$(($valpct + ($isopct / $divpct)))
                else
                     isoout=$(($isopct / $divpct))
                fi
           fi
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
   
   if [[ $fstyp == "FAT"* ]] ; then
      sudo -v #Refresh credentials for unmount.
   fi
  
   while kill -0 $BUFF_PID 2> /dev/null; do
         if [[ "$usezenity" == "true" ]]; then
            echo "# Writing files to disk..."  
         fi
         dirty=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         bufpct=$(((($isoextsz - ($dirty * $kbyte)) * 100) / $isoextsz))
         if   [[ "$usezenity" == "true" ]]; then
              if   [ $divpct -gt 1 ]; then
                   bufout=$(($isoout + ($bufpct / $divpct)))
                   valpct=$bufout
              else
                   bufout=$(($bufpct / $divpct))
              fi
              echo $bufout
         else
              echo -ne "Write files to disk:" $bufpct"%"\\r
         fi
   done

   if [[ "$usezenity" == "false" ]]; then
      echo "Write files to disk: 100%"
   fi
   
   if [[ $fstyp == "EXT4" ]] ; then
      if [[ "$usezenity" == "true" ]]; then printf "# "; fi
      echo "Set owner and permissions..."
      sudo chown -R root:root "$2"
      sudo chmod -R 777 "$2"
   fi
fi
}

config_persist () {

i=0
pstarg="persistent"
pstname="$pstarg"
pstconf="false"
configs=()
schterms=("/casper/vmlinuz" "/live/vmlinuz" "boot=casper" "rd.live.image" "rd.live.squashimg")

while [[ -z "${configs[@]}" ]]; do
      readarray -t configs <<< $(grep -r -m 1 --exclude-dir='.*' --include=\*.cfg "${schterms[$i]}" "$1" | awk -F: '{print $1}')
      if [[ ! -z "${configs[@]}" ]]; then
         if   [[ "${schterms[$i]}" == "/live/vmlinuz" ]]; then
              pstarg="persistence"
              pstname="$pstarg"
              if [[ $system == "Linux" ]]; then pstconf="true"; fi
              if [[ $system == "Darwin" ]]; then pstconf="alert"; fi
         elif [[ "${schterms[$i]}" == "rd.live."* ]]; then
              pstarg="rd.live.overlay=LABEL=$extlabel:persistence.img"
              pstname="rd.live.overlay"
         fi
         break
      fi
      ((i++)) #Next search term
done

for key in "${!configs[@]}"
do
    if   [[ $overlay == "true" ]]; then
         lnum_vmlz=$(grep -nwi -m 1 "${configs[$key]}" -e "${schterms[$i]}" | awk -F: '{print $1}')
    else
         lnum_vmlz=$(grep -nwi -m 1 "${configs[$key]}" -e 'vmlinuz' | awk -F: '{print $1}')
    fi
    lnum_appnd=$(grep -nwi -m 1 "${configs[$key]}" -e 'append' | awk -F: '{print $1}')
    if   [[ ! -z "$lnum_appnd" ]]; then
         if [[ "$usezenity" == "true" ]]; then echo "60"; printf "# "; fi
         echo "Add $pstname option to $(basename "${configs[$key]}")"
         if   [[ $system == "Darwin" ]]; then
              sed -i '' "$lnum_appnd""s/$/ $pstarg/" "${configs[$key]}"
         elif [[ $system == "Linux" ]]; then
              sed -i "$lnum_appnd""s/$/ $pstarg/" "${configs[$key]}"
         fi
    else
         if [[ "$usezenity" == "true" ]]; then echo "65"; printf "# "; fi
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
   if [[ "$usezenity" == "true" ]]; then echo "70"; printf "# "; fi
   if   [[ $system == "Darwin" && $pipeview == "true" ]]; then
        if   [[ "$usezenity" == "true" ]]; then
             echo "Creating persistent overlay image..."
             pv < /dev/zero -nYSs $volfreeblks"M" -o "$2"/persistence.img 2>&1 | awk '{print int(70 + $1 / 10)}'
        else
             pv < /dev/zero -N 'Creating persistent overlay image' -F '%N %{progress-amount-only}' -YSs $volfreeblks"M" -o "$2"/persistence.img
        fi
   else
        echo "Creating persistent overlay image..."
        sudo dd if=/dev/zero of="$2"/persistence.img bs="$3" count=$volfreeblks status=none
   fi
   if [[ "$usezenity" == "true" ]]; then echo "80"; printf "# "; fi
   echo "Formatting persistent overlay image..."
   sudo mkfs.ext4 -q -L persistence "$2"/persistence.img > /dev/null
   if   [[ $system == "Linux" ]]; then
        if [[ "$usezenity" == "true" ]]; then echo "85"; printf "# "; fi
        echo "Creating folders on the persistent image..."
        imgblkdev=$(sudo losetup --find --show "$2"/persistence.img)
        sleep 3 && gio mount -d "$imgblkdev"
        overlay_folder="/media/$USER/persistence/overlayfs"
        ovlwork_folder="/media/$USER/persistence/ovlwork"
        sudo mkdir -m 0755 "$overlay_folder" "$ovlwork_folder"
        sudo setfattr -n security.selinux -v "system_u:object_r:root_t:s0" "$overlay_folder" "$ovlwork_folder"
        umount "$imgblkdev" && sudo losetup -d "$imgblkdev"
   elif [[ $system == "Darwin" ]]; then
        echo -e "${YELLOW}Create the required folders on the persistent image.${NC}"
        echo -e "${YELLOW}See the overlay section of the About menu for details.${NC}"
   fi
fi
}

get_syslinux_path () {
echo $(find "$1" -type d -name "$2" 2>&1 | grep -vE "Permission denied|Operation not permitted")
}

rename_isolinux () {
if mv "$1"/isolinux "$1"/syslinux 2> /dev/null; then
   echo "Rename isolinux files to syslinux..."
   mv "$1"/syslinux/isolinux.bin "$1"/syslinux/syslinux.bin
   mv "$1"/syslinux/isolinux.cfg "$1"/syslinux/syslinux.cfg
fi
}

update_cdlabel () {
i=0
config=""
schterms=("rd.live.image" "rd.live.squashimg")

while [[ -z "$config" ]]; do
      config=$(grep -r -m 1 --exclude-dir='.*' --include=\grub.cfg "${schterms[$i]}" "$1" | awk -F: '{print $1}')
      ((i++)) #Next search term
done
echo "Update $(basename "$config") with new volume label..."
if   [[ $system == "Darwin" ]]; then
     sed -i '' "s/default=\"1\"/default=\"0\"/" "$config"
     sed -i '' "s/$isolabel/$label/g" "$config"
elif [[ $system == "Linux" ]]; then
     sed -i "s/default=\"1\"/default=\"0\"/" "$config"
     sed -i "s/$isolabel/$label/g" "$config"
fi
}

mkgrubefi () {
echo "Move grub boot folders to EFI..."
if   [[ $fstyp == "EXT4" ]] ; then
     mv "$1"/EFI "$2"
     mkdir -p "$2"/boot/grub
     cp "$1"/"$efigrubcfg" "$2"/boot/grub/grub.cfg
     vsn=$(lsblk -o UUID /dev/$drive"$isopart" | awk 'NR==2')
     idfile="$(uuidgen).id"
     touch "$1/$idfile"
     sudo chown root:root "$1/$idfile"
     sudo chmod 777 "$1/$idfile"
     sed -i 's/main_uuid="%UUID%"/main_uuid="'$vsn'"/' "$2"/boot/grub/grub.cfg
     sed -i 's/id_file="%ID_FILE%"/id_file="\/'$idfile'"/' "$2"/boot/grub/grub.cfg
elif 
     [[ $fstyp == "EXFAT" ]] ; then
     mv "$1"/EFI "$2"
     mkdir -p "$2"/boot/grub/x86_64-efi
     cp "$1"/"$efigrubcfg" "$2"/boot/grub/grub.cfg
     cp "$1"/"$efigrubmod" "$2"/boot/grub/x86_64-efi
     vsn=$(echo "${vsnbytes:0:${#vsnbytes}/2}-${vsnbytes:${#vsnbytes}/2}")
     idfile="$(uuidgen).id"
     touch "$1/$idfile"
     sed -i '' 's/main_uuid="%UUID%"/main_uuid="'$vsn'"/' "$2"/boot/grub/grub.cfg
     sed -i '' 's/id_file="%ID_FILE%"/id_file="\/'$idfile'"/' "$2"/boot/grub/grub.cfg
     sed -i '' '/id_file/a\'$'\ninsmod exfat'$'\n' "$2"/boot/grub/grub.cfg
     sed -i '' '/id_file/a\'$'\n'$'\n' "$2"/boot/grub/grub.cfg
fi
}

checksum_files () {
if   [[ "$persist" == "true" ]]; then
     cd "$1"
     rm "$2.txt"
     echo "Create new $2.txt file..."
     if   [[ $system == "Darwin" ]]; then
          find . -type f -not -name "$2.txt" -not -name "$3.txt" -exec $2 '{}' \; 2> /dev/null > "$2.txt"
     elif [[ $system == "Linux" ]]; then
          find -type f -not -name "$2.txt" -not -name "$3.txt" -exec $2 '{}' \; > "$2.txt"
     fi
elif grep -q "isolinux" "$1/$2.txt"; then
     echo "Update $2.txt file..."
     if   [[ $system == "Darwin" ]]; then
          sed -i '' 's/isolinux/syslinux/g' "$1/$2.txt"
     elif [[ $system == "Linux" ]]; then
          sed -i 's/isolinux/syslinux/g' "$1/$2.txt"
     fi
fi
}

# Verify selected drive is valid and run actions.

if    [[ $erase == "true" && -e /dev/$drive ]]; then
      if [[ $system == "Darwin" ]]; then
         have_sgdisk="false"
         if [[ ! -z $(command -v sgdisk) ]]; then have_sgdisk="true"; fi
         ignore_btn="osascript ./click_ignore.scpt" #Close macOS disk warning dialogue.
         devblksz=$(diskutil info $drive | grep 'Device Block Size:' | awk '{print $4}')
         disk_length=$(diskutil info $drive | grep "Disk Size:" | awk '{print $8}')
         disk_size=$(diskutil info $drive | grep "Disk Size:" | awk '{print $5}' | cut -c2-)
         mibblksz=$(($mbyte / $devblksz))
         if [[ $fstyp == "FAT16" && $disk_size -ge $(($gbyte * 2)) ]]; then
            echo -e "${YELLOW}Format as FAT32 when disk is greater than 2.0GB.${NC}"
            echo
            read -p "Press any key to continue... " -n1 -s
            exit 1
         fi
         if [[ "$persist" == "true" ]]; then
            isobytesz=$(stat -f %z "$isofile")
            if [[ $isoextsz -gt $isobytesz ]]; then
               isobytesz=$isoextsz                        #Use extracted size if larger
            fi
            isomibsz=$(($isobytesz / $mbyte))             #ISO size in whole MiBs
            isopartmib=$(($isomibsz + 50))                #ISO partition with padding
            isoblksz=$((($isomibsz * $mbyte) / devblksz)) #ISO size in sectors
            isoblkpad=$((($mbyte * 50) / $devblksz))      #50MiBs padding in sectors
            isopartblk=$(($isoblksz + $isoblkpad))         #ISO partition in sectors
            if [[ "$pstpart" != "deferred" && "$pstpart" != "END" ]]; then
               unit_sizes "$pstpart"
               lnxpartszbytes=$((${pstpart%?} * $baseunit))
               lnxpartlenblks=$(($lnxpartszbytes / $devblksz))
               if   [[ $prtshm == "GPT" && "$have_sgdisk" == "true" ]]; then
                    isopart_offset=$(($kbyte * 20))
               else
                    isopart_offset=$mbyte
               fi
               usedbytes=$((($isopartmib * $mbyte) + $isopart_offset)) #ISO partition and offset
               if [[ $hasgrub == "true" ]]; then
                  usedbytes=$(($usedbytes + $mbyte)) #BIOS Boot Partition
               fi
               freebytes=$(($disk_size - $usedbytes))
               if [[ $lnxpartszbytes -ge $freebytes ]]; then
                  available=$(($freebytes / $errunit))
                  echo -e "${YELLOW}Insufficient free space for persistent partition.${NC}"
                  echo "Please specifiy a maximum size of up to $available$errsym."
                  echo
                  read -p "Press any key to continue... " -n1 -s
                  exit 1
               fi
               if [[ "$datapart" == "true" ]]; then
                  databytes=$(($freebytes - $lnxpartszbytes))
                  if   [[ $databytes -gt $mbyte ]]; then
                       datapartsz=$(($databytes / $mbyte))                 #Free space in whole MiBs
                       datapartlen=$((($datapartsz * $mbyte) / $devblksz)) #Free space in sectors
                       if   [[ $databytes -gt $(($gbyte * 4)) ]]; then
                            datapty=7; datafs="EXFAT"
                       elif [[ $databytes -gt $(($mbyte * 500)) ]]; then
                            datapty=c; datafs="FAT32"
                       else
                            datapty=e; datafs="FAT16"
                       fi
                  else
                       echo -e "${YELLOW}Insufficient space remaining for data partition.${NC}"
                       echo
                       read -p "Press any key to continue... " -n1 -s
                       exit 1
                  fi
               fi
            fi
         fi
         if [[ $prtshm == "ERASE" ]]; then
            disk_offset=$(($disk_length - $mibblksz))
            echo "Unmount volumes..."
            diskutil unmountDisk $drive > /dev/null
            echo "Erase MBR/GPT structures (sudo required)..."
            sudo chmod o+rw /dev/$drive
            dd if=/dev/zero of=/dev/$drive bs=1m count=2 2> /dev/null
            dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
            apply_image "$isofile" "$drive" "4m" && $ignore_btn &> /dev/null
            if [[ "$usezenity" == "false" ]]; then sleep 2; fi
            exit 0
         fi
         echo "Partition and format disk (sudo required)..."
         hds=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f2 -d"/")
         spt=$(sudo fdisk /dev/$drive | grep "geometry:" | awk '{print $4}' | cut -f3 -d"/")
         if   [[ $prtshm == "MBR" ]]; then
              disk_mbytes=$(($disk_size / $mbyte))                 #Disk space in whole MiBs
              disk_blocks=$((($disk_mbytes * $mbyte) / $devblksz)) #Disk space in sectors
              diskutil eraseDisk "Free Space" %noformat% MBR $drive > /dev/null
              sudo chmod o+rw /dev/$drive
              if   [[ "$persist" == "true" ]]; then
                   partnum=1
                   fdargs=("e $partnum" "$pty" "" "$mibblksz" "$isopartblk" "f 1")
                   if [[ "$pstpart" != "deferred" ]]; then
                      partnum=$(($partnum + 1))
                      if [[ "$overlay" == "true" ]]; then pstprtyp=7; else pstprtyp=83; fi
                      if [[ "$pstpart" == "END" ]]; then
                         lnxpartlenblks="$(($disk_blocks - ($mibblksz + $isopartblk)))"
                      fi
                      fdargs+=("e $partnum" "$pstprtyp" "" "" "$lnxpartlenblks")
                   fi
                   if [[ $datapartsz != "0"  ]]; then
                      partnum=$(($partnum + 1))
                      fdargs+=("e $partnum" "$datapty" "" "" "$datapartlen")
                   fi
                   fdargs+=("q")
                   printf "%s\n" "${fdargs[@]}" | fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
              elif [[ $pty == "7" ]]; then
                   efiblksz=$((($mbyte * 50) / $devblksz))
                   isopartsz=$(($disk_blocks - ($mibblksz + $efiblksz)))
                   printf 'e 1\nb\n\n'$mibblksz'\n'$efiblksz'\ne 2\n'$pty'\n\n\n'$isopartsz'\nf 2\nq\n' | \
                   fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
              else
                   isopartsz=$(($disk_blocks - $mibblksz))
                   printf 'e 1\n'$pty'\n\n'$mibblksz'\n'$isopartsz'\nf 1\nq\n' | \
                   fdisk -y -e /dev/$drive &> /dev/null && $ignore_btn &> /dev/null
              fi
         elif [[ $prtshm == "GPT" ]]; then
              if   [[ "$have_sgdisk" == "true" ]]; then
                   diskutil eraseDisk -noEFI "Free Space" %noformat% GPT $drive > /dev/null
                   sudo chmod o+rw /dev/$drive
                   if [[ $hasgrub == "true" ]]; then
                      sgdisk -n 0:0:+1M -t '0:EF02' -c 0:"GRUB BIOS" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                   fi
                   if   [[ "$persist" == "true" ]]; then
                        sgdisk -n '0:0:+'$isopartmib'M' -t '0:0700' -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                        if [[ "$pstpart" != "deferred" ]]; then
                           if   [[ $pstpart == "END" ]]; then
                                pstpartblks="0"
                           else
                                pstpartblks="+$pstpart"
                           fi
                           if [[ "$overlay" == "true" ]]; then pstprtyp="0700"; else pstprtyp="8300"; fi
                           sgdisk -I -n '0:0:'$pstpartblks -t 0:$pstprtyp -c 0:$extlabel /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                        fi
                        if [[ $datapartsz != "0"  ]]; then
                           sgdisk -I -n 0:0:0 -t '0:0700' -c 0:"STORAGE" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                        fi
                   elif [[ $fstyp == "EXFAT" ]]; then
                        sgdisk -n 0:0:+50M -t '0:0700' -c 0:"GRUB UEFI" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                        sgdisk -I -n 0:0:0 -t '0:0700' -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                   else
                        sgdisk -I -n 0:0:0 -t '0:0700' -c 0:"$label" /dev/$drive > /dev/null 2>&1 && $ignore_btn &> /dev/null
                   fi
              else
                   parts=0
                   if [[ $hasgrub == "true" ]]; then
                      parts=$(($parts + 1))
                      diskargs=(%$biospty% %noformat% 1MiB )
                   fi
                   if   [[ "$persist" == "true" ]]; then
                        parts=$(($parts + 1))
                        diskargs+=(%$pty% %noformat% $isopartmib'MiB' )
                        if [[ "$pstpart" != "deferred" ]]; then
                           if   [[ $pstpart == "END" ]]; then
                                parts=$(($parts + 1))
                                if [[ "$overlay" == "true" ]]; then pstprtyp="$pty"; else pstprtyp="$linuxpty"; fi
                                diskargs+=(%$pstprtyp% %noformat% R)
                           else
                                if [[ "$overlay" == "true" ]]; then pstprtyp="$pty"; else pstprtyp="$linuxpty"; fi
                                parts=$(($parts + 1))
                                diskargs+=(%$pstprtyp% %noformat% $pstpart)
                           fi
                        fi
                        if   [[ $datapartsz != "0"  ]]; then
                             parts=$(($parts + 1))
                             diskargs+=( %$pty% %noformat% R)
                        elif [[ $pstpart != "END" ]]; then
                             parts=$(($parts + 1))
                             diskargs+=( "Free Space" %noformat% R)
                        fi
                        diskutil partitionDisk -noEFI $drive $parts GPT "${diskargs[@]}" > /dev/null
                   elif [[ $fstyp == "EXFAT" ]]; then
                        parts=$(($parts + 2))
                        diskargs+=(%$pty% %noformat% 50M %$pty% %noformat% R)
                        diskutil partitionDisk -noEFI $drive $parts GPT "${diskargs[@]}" > /dev/null
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
         if   [[ $fstyp == "FAT16" || $fstyp == "FAT32" ]]; then
              if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
              sudo newfs_msdos -u $spt -h $hds -F $fatsz -v "$label" /dev/$drive's'$isopart > /dev/null
         elif [[ $fstyp == "EXFAT" ]]; then
              if [[ $hasgrub == "true" ]]; then efipart=2; else efipart=1; fi
              if [[ $hasgrub == "true" ]]; then isopart=3; else isopart=2; fi
                 sudo newfs_msdos -u $spt -h $hds -F 32 -v GRUB /dev/$drive's'$efipart > /dev/null
                 sudo newfs_exfat -v $label /dev/$drive's'$isopart > /dev/null
                 vsnbytes=$(sudo dd if=/dev/$drive's'$isopart skip=100 bs=1 count=4 2>/dev/null | hexdump -e '4/4 "%X"')
         fi
         if [[ "$persist" == "true" ]]; then
            if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
            if   [[ "$overlay" == "true" ]]; then
                 sudo newfs_exfat -v $extlabel /dev/$drive's'$extpart > /dev/null
            else
                 sudo mkfs.ext4 -q -L $extlabel /dev/$drive's'$extpart > /dev/null
            fi
            if [[ $datapartsz != "0"  ]]; then
               if [[ $hasgrub == "true" ]]; then fatpart=4; else fatpart=3; fi
               if   [[ "$datafs" == "FAT16" || "$datafs" == "FAT32" ]]; then
                    sudo newfs_msdos -u $spt -h $hds -F ${datafs:3} -v DATA /dev/$drive's'$fatpart > /dev/null
               elif [[ "$datafs" == "EXFAT" ]]; then
                    sudo newfs_exfat -v DATA /dev/$drive's'$fatpart > /dev/null
               fi
            fi
         fi
         echo "Mount boot disk..."
         if [[ $fstyp == "EXFAT" ]]; then
            diskutil mount $drive's'$efipart > /dev/null
         fi
         diskutil mount $drive's'$isopart > /dev/null
         if [[ "$overlay" == "true" ]]; then
            if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
            diskutil mount $drive's'$extpart > /dev/null
         fi
         if [[ $datapartsz != "0"  ]]; then
            diskutil mount $drive's'$fatpart > /dev/null
         fi
         echo "Disable Spotlight indexing..."
         mdutil -d /Volumes/"$label" &> /dev/null
         if [[ $fstyp == "EXFAT" ]]; then
            mdutil -d /Volumes/GRUB &> /dev/null
         fi
         if [[ "$overlay" == "true" ]]; then
            mdutil -d /Volumes/"$extlabel" &> /dev/null
         fi
         if [[ $datapartsz != "0"  ]]; then
            mdutil -d /Volumes/DATA &> /dev/null
         fi
         extract_files "$isofile" /Volumes/"$label"
         isolinuxdir=$(get_syslinux_path /Volumes/"$label" isolinux)
         syslinuxdir=$(get_syslinux_path /Volumes/"$label" syslinux)
         if   [[ ! -z "$isolinuxdir" && ! -z "$syslinuxdir" ]]; then
              if [[ $fstyp == "EXFAT" ]]; then
                 echo "Remove unneeded syslinux files..."
                 rm -r "$syslinuxdir"
              fi
              echo "Remove unneeded isolinux files..."
              rm -r "$isolinuxdir"
         elif [[ ! -z "$isolinuxdir" && -z "$syslinuxdir" ]]; then
              if   [[ $fstyp == "EXFAT" ]]; then
                   echo "Remove unneeded isolinux files..."
                   rm -r "$syslinuxdir"
              else
                   rename_isolinux "$(dirname "$isolinuxdir")"
              fi
         fi
         if [[ $fstyp == "EXFAT" && -f /Volumes/"$label"/"$efigrubcfg" ]]; then
            mkgrubefi /Volumes/"$label" /Volumes/GRUB
         fi
         if [[ "$usblabel" == "true" ]]; then
            update_cdlabel /Volumes/"$label"
         fi
         if [[ "$persist" == "true" ]]; then
            if  [[ "$pupsave" == "true" ]]; then
                echo "SS_ID=$extlabel" > /Volumes/"$label"/SAVESPEC
            else
                config_persist /Volumes/"$label" /Volumes/"$extlabel" "1m"
            fi
         fi
         if [[ -f /Volumes/"$label"/md5sum.txt ]]; then
            checksum_files /Volumes/"$label" md5sum sha256sum
         fi
         if [[ -f /Volumes/"$label"/sha256sum.txt ]]; then
            checksum_files /Volumes/"$label" sha256sum md5sum
         fi
         read -p "Finished! Press any key to exit." -n1 -s
         exit 0
      fi
      if  [[ $system == "Linux" ]]; then
          if   [[ "$pstpart" == "getmaxsize" ]]; then
               disk_size=$(lsblk --nodeps -nbo SIZE /dev/$drive)
          else
               if   [[ "$usezenity" == "true" ]]; then
	            zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	            if [[ $? -ne 0 ]]; then exit 1; fi
	       else
	            echo "Reading device information (sudo required)..."
               fi
               sudo chmod o+rw /dev/$drive
               devblksz=$(blockdev --getss /dev/$drive)
               disk_size=$(blockdev --getsize64 /dev/$drive)
               disk_length=$(sfdisk -l /dev/$drive 2> /dev/null | grep "Disk /dev/$drive:" | awk '{print $7}')
          fi
	  
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

	  if [[ "$persist" == "true" ]]; then
	     isobytesz=$(stat -c %s "$isofile")
	     if [[ $isoextsz -gt $isobytesz ]]; then
	       isobytesz=$isoextsz
	     fi
	     isomibsz=$(($isobytesz / $mbyte))     #ISO size in whole MiBs
	     isopartsz=$(($isomibsz + 50))         #ISO partition with padding
	     isopartbytes=$(($isopartsz * $mbyte)) #ISO partition in bytes
	     if [[ "$pstpart" != "+" ]]; then
                usedbytes=$(($isopartbytes + $mbyte)) #ISO partition and offset
                if [[ $hasgrub == "true" ]]; then
                   usedbytes=$(($usedbytes + $mbyte)) #BIOS Boot Partition
                fi
                freebytes=$(($disk_size - $usedbytes))
                if   [[ "$pstpart" == "getmaxsize" ]]; then
                     echo $(($freebytes / $mbyte))
                     exit 0
                else
                     unit_sizes "$pstpart"
                     lnxpartszbytes=$((${pstpart%?} * $baseunit))
                fi
                if [[ $lnxpartszbytes -ge $freebytes ]]; then
                   available=$(($freebytes / $errunit))
                   if   [[ "$usezenity" == "true" ]]; then
                        zenity --height=160 --width=375 --error --title="Disk Space Error" \
                        --text="Insufficient free space for persistent partition.\nPlease specifiy a maximum size of up to $available$errsym."
                   else
                        echo -e "${YELLOW}Insufficient free space for persistent partition.${NC}"
                        echo "Please specifiy a maximum size of up to $available$errsym."
                        echo
                        read -p "Press any key to continue... " -n1 -s
                   fi
                   exit 1
                fi
                if [[ "$datapart" == "true" ]]; then
                   databytes=$(($freebytes - $lnxpartszbytes))
                   if   [[ $databytes -gt $mbyte ]]; then
                        datapartsz=$(($databytes / $mbyte))
                        if   [[ $databytes -gt $(($gbyte * 4)) && "$mkexfat" == "true" ]]; then
                             datapty=7; datafs="EXFAT"
                        elif [[ $databytes -gt $(($mbyte * 500)) ]]; then
                             datapty=c; datafs="FAT32"
                        else
                             datapty=e; datafs="FAT16"
                        fi
                   else
                        if   [[ "$usezenity" == "true" ]]; then
                             zenity --error --title="Disk Space Error" \
                             --text="Insufficient space remaining for data partition."
                        else
                             echo -e "${YELLOW}Insufficient space remaining for data partition.${NC}"
                             echo
                             read -p "Press any key to continue... " -n1 -s
                        fi
                        exit 1
                   fi
                fi
             fi
	  fi
	  (
	  echo "Unmount volumes..."
	  umount /dev/$drive?
	  if [[ "$usezenity" == "true" ]]; then
	     if   [[ $prtshm == "ERASE" ]]; then
	          echo "0"; echo "# Initializing disk..."
             else
	          echo "10"; printf "# "
	     fi
	  fi
	  echo "Erase MBR/GPT structures..."
          mibblksz=$(($mbyte / $devblksz))
          disk_offset=$(($disk_length - $mibblksz))
	  dd if=/dev/zero of=/dev/$drive bs=1M count=2 2> /dev/null
	  dd if=/dev/zero of=/dev/$drive seek=$disk_offset 2> /dev/null
	  if   [[ $prtshm == "ERASE" ]]; then
	       apply_image "$isofile" "$drive" "4M"
           if [[ "$usezenity" == "false" ]]; then sleep 2; fi
           exit 0
	  fi
	  if [[ "$usezenity" == "true" ]]; then echo "15"; printf "# "; fi
	  echo "Partition and format disk..."
	  if   [[ $prtshm == "MBR" ]]; then
	       if   [[ "$persist" == "true" ]]; then
	            sfdargs=(,$isopartsz'M',$pty,*\\n,$pstpart,L)
	            if [[ $datapartsz != "0"  ]]; then sfdargs+=(\\n,$datapartsz'M',$datapty); fi
	            echo -e "${sfdargs[@]}" | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	       elif [[ $fstyp == "EXT4" ]]; then
	            echo -e ',50M,b\n,,L,*' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	       else
	            echo ',,'$pty',*;' | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	       fi
	  elif [[ $prtshm == "GPT" ]]; then
	       if [[ $hasgrub == "true" ]]; then
	          sfdargs=(size=1M,type=$biospty,name='"'GRUB BIOS'"'\\n)
	       fi
	       if   [[ "$persist" == "true" ]]; then
	            sfdargs+=(size=$isopartsz'M',type=$pty,name='"'$label'"'\\n)
	            sfdargs+=(size=$pstpart,type=L,name='"'$extlabel'"')
	            if [[ $datapartsz != "0"  ]]; then sfdargs+=(\\ntype=$pty,name='"'STORAGE'"'); fi
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       elif [[ $fstyp == "EXT4" ]]; then
	            sfdargs+=(size=50M,type=$pty,name='"'GRUB UEFI'"'\\n)
	            sfdargs+=(type=L,name='"'$label'"')
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       else
	            sfdargs+=(type=$pty,name='"'$label'"')
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       fi
	  fi
	  if   [[ $fstyp == "EXT4" ]] ; then
	       if [[ $hasgrub == "true" ]]; then isopart=3; else isopart=2; fi
	       sudo mkfs.ext4 -q -L "$label" /dev/$drive"$isopart" > /dev/null
	       if [[ $hasgrub == "true" ]]; then efipart=2; else efipart=1; fi
	       sudo mkfs.fat -F 32 -n GRUB /dev/$drive"$efipart" > /dev/null
	  else
	       if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
	       sudo mkfs.fat -F $fatsz -n "$label" /dev/$drive"$isopart" > /dev/null
	  fi
	  if [[ "$persist" == "true" ]]; then
	     if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
	     sudo mkfs.ext4 -q -L "$extlabel" /dev/$drive"$extpart" > /dev/null
	     if [[ $datapartsz != "0" ]]; then
	        if [[ $hasgrub == "true" ]]; then fatpart=4; else fatpart=3; fi
	        if   [[ "$datafs" == "FAT16" || "$datafs" == "FAT32" ]]; then
	             sudo mkfs.fat -F ${datafs:3} -n DATA /dev/$drive"$fatpart" > /dev/null
	        elif [[ "$datafs" == "EXFAT" ]]; then
	             sudo mkfs.exfat -L DATA /dev/$drive"$fatpart" > /dev/null
	        fi
	     fi
	  fi
	  if [[ "$usezenity" == "true" ]]; then echo "20"; printf "# "; fi
	  echo "Mount boot disk..." && sleep 1
	  if   [[ $fstyp == "EXT4" ]] ; then
	       gio mount -d /dev/$drive"$efipart"
	       gio mount -d /dev/$drive"$isopart"
	       isovolpath="/media/$USER/$label"
	       sudo chmod -R 777 "$isovolpath"
	  else
	       isovolpath="/mnt/isovolume"
	       isovolopts="defaults,nosuid,nodev,uid=$(id -u),gid=$(id -g),showexec,utf8"
	       sudo mkdir $isovolpath
	       sudo mount -o $isovolopts /dev/$drive"$isopart" $isovolpath
	  fi
	  if [[ "$persist" == "true" ]]; then
	     gio mount -d /dev/$drive"$extpart"
	     if [[ $datapartsz != "0"  ]]; then
	        gio mount -d /dev/$drive"$fatpart"
	     fi
	  fi
	  if [[ "$usezenity" == "true" ]]; then
	     if   [[ "$persist" == "true" ]]; then
	          pctval=40; pctdiv=10; echo "$pctval"
	     else
	          pctval=30; pctdiv=4; echo "$pctval"
	     fi
	  fi
	  extract_files "$isofile" "$isovolpath" $pctval $pctdiv
	  if [[ $fstyp == "FAT"* ]] ; then
	     sudo umount $isovolpath && sudo rm -r $isovolpath
	     gio mount -d /dev/$drive"$isopart"
	  fi
	  isolinuxdir=$(get_syslinux_path /media/$USER/"$label" isolinux)
	  syslinuxdir=$(get_syslinux_path /media/$USER/"$label" syslinux)
	  if   [[ ! -z "$isolinuxdir" && ! -z "$syslinuxdir" ]]; then
	       if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	       echo "Remove unneeded isolinux files..."
	       rm -r "$isolinuxdir"
	  elif [[ ! -z "$isolinuxdir" && -z "$syslinuxdir" ]]; then
	       if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	       rename_isolinux "$(dirname "$isolinuxdir")"
	  fi
	  if [[ $fstyp == "EXT4" && -f /media/$USER/"$label"/"$efigrubcfg" ]]; then
	     if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	     mkgrubefi /media/$USER/"$label" /media/$USER/GRUB
	  fi
	  if [[ "$usblabel" == "true" ]]; then
	     if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	     update_cdlabel /media/$USER/"$label"
	  fi
	  if [[ "$persist" == "true" ]]; then
	     if  [[ "$pupsave" == "true" ]]; then
	         if [[ "$usezenity" == "true" ]]; then echo "60"; fi
                 echo "SS_ID=$extlabel" > /media/$USER/"$label"/SAVESPEC
             else
                 config_persist /media/$USER/"$label" /media/$USER/"$extlabel" "1M"
             fi
	  fi
	  if [[ -f /media/$USER/"$label"/md5sum.txt ]]; then
	     if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
	     checksum_files /media/$USER/"$label" md5sum sha256sum
	  fi
	  if [[ -f /media/$USER/"$label"/sha256sum.txt ]]; then
	     if [[ "$usezenity" == "true" ]]; then echo "95"; printf "# "; fi
	     checksum_files /media/$USER/"$label" sha256sum md5sum
	  fi
	  if   [[ "$usezenity" == "true" ]]; then
	       echo "100"; echo "# Finished!"
	  else
	       read -p "Finished! Press any key to exit." -n1 -s
	  fi
	  ) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
	  exit 0
      fi
elif  [[ $erase == "false" && -e "$drive" ]]; then
      (
      extract_files "$isofile" "$drive" "0" "1"
      if [[ "$usezenity" == "true" ]]; then echo "100"; printf "# "; fi
      echo "Finished!"
      ) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs; else cat; fi
      if [[ "$usezenity" == "false" ]]; then sleep 1; fi
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
