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
fmtyp="$8"
fspst="$9"
fmpst="${10}"
verbose="${11}"
label="${12}"
usezenity="${13}"
erase="false"
persist="false"
hasgrub="false"
usblabel="false"
overlay="false"
pupsave="false"
pipeview="false"

kbyte=1024
mbyte=1048576
gbyte=1073741824
tbyte=1099511627776

datapartsz=0

RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ ! -z $(command -v pv) ]]; then pipeview="true"; fi

if  [[ "$usezenity" == "true" ]]; then
    zenprogargs='--width=300 --progress --no-cancel --title="BOOTDISK: Linux/Other"'
    zenvfmtargs='--width=550 --height=400 --text-info --title="Verbose Format Information"'
    zenwipeargs="$zenprogargs"
    if [[ $fmtyp == "FULL"* ]]; then
       if [[ $fstyp == "EXT"* || ($fstyp == "FAT"* && $pipeview == "false") ]]; then
          zenwipeargs+=' --pulsate'
       fi
    fi
fi

if [[ $verbose == "true" ]]; then
   dspmode="-v"
   boarder="-------------------------------------"
fi

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
if [[ $fstyp == "FAT"* ]] ; then
   mkftargs=(-F ${fstyp:3})
   if [[ $system == "Linux" ]]; then
      isovolpath="/mnt/isovolume"
      isovolopts="defaults,nosuid,nodev,uid=$(id -u),gid=$(id -g),showexec,utf8"
      if [[ $fmtyp == "FULL" ]]; then mkftargs+=(-c); fi
      if [[ $verbose == "true" ]]; then mkftargs+=(-v); fi
   fi
fi
if [[ $fstyp == "EXT"* ]]; then
   mke2isoargs=(-t "${fstyp,,}")
   if   [[ $fmtyp == "FULL-READ" ]]; then
        mke2isoargs+=(-c)
   elif [[ $fmtyp == "FULL-WRITE" ]]; then
        mke2isoargs+=(-cc)
   fi
   mke2isoargs+=(-L "$label")
fi
if [[ $prtshm == "ERASE" ]]; then
   erase="true"                         #Wipe disk and apply image.
   if [[ $pipeview == "false" ]]; then
      zenprogargs+=' --pulsate'         #No progress bar without pipeviewer.
   fi
fi
if [[ $prtshm == "NONE" && "$pstpart" == "getmaxsize" ]]; then
   erase="true"                       #Get maximum size for persistence partition.
fi
if [[ $prtshm == "CURRENT" ]]; then
   erase="false"                      #Just extract image to disk.
   if [[ $system == "Linux" ]]; then
      ufdvolpath="$drive"
      format=$(lsblk -o path,fstype,mountpoint | grep "$drive" | awk '{print $2}')
      if [[ $format == "vfat" ]]; then
         ufdvolpath="/mnt/ufdvolume"
         ufdvolopts="defaults,nosuid,nodev,uid=$(id -u),gid=$(id -g),showexec,utf8"
         device=$(lsblk -o path,fstype,mountpoint | grep "$drive" | awk '{print $1}')
      fi
   fi
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
   mke2pstargs=(-t "${fspst,,}")
   if   [[ $fmpst == "FULL-READ" ]]; then
        mke2pstargs+=(-c)
   elif [[ $fmpst == "FULL-WRITE" ]]; then
        mke2pstargs+=(-cc)
   fi
   mke2pstargs+=(-L "$extlabel")
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
      #Refresh credentials for unmount if still active.
      if sudo -nv 2>/dev/null; then sudo -v; fi
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
   
   if [[ $fstyp == "EXT"* ]] ; then
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
   echo "Creating $fspst file system on overlay image..."
   if   [[ $system == "Linux" ]]; then
        sudo mke2fs -q -t "${fspst,,}" -L persistence "$2"/persistence.img
   elif [[ $system == "Darwin" ]]; then
        mke2pstargs=(${mke2pstargs[@]//$extlabel/persistence}) #Update image volume label.
        if [[ $verbose == "true" ]]; then echo $boarder; fi
        sudo mke2fs "${mke2pstargs[@]}" "$2"/persistence.img
        if [[ $verbose == "true" ]]; then echo $boarder; fi
   fi
   if   [[ $system == "Linux" ]]; then
        if [[ "$usezenity" == "true" ]]; then echo "85"; printf "# "; fi
        echo "Creating folders on the persistent image..."
        imgblkdev=$(sudo losetup --find --show "$2"/persistence.img)
        sleep 3 && gio mount -d "$imgblkdev"
        overlay_folder="$media_path/persistence/overlayfs"
        ovlwork_folder="$media_path/persistence/ovlwork"
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
if   [[ $fstyp == "EXT"* ]] ; then
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

zero_part () {
ddargs="conv=fsync oflag=direct status=none"
if   [[ $pipeview == "true" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          (echo "# Writing zeros to \"$4\" volume..."
          if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	      zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	      if [[ $? -ne 0 ]]; then
	         echo "# Volume erase operation canceled."
                 exit 1
	      fi
	  fi
          pv < /dev/zero -ns $3 | sudo dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null) 2>&1 | eval zenity $zenwipeargs
     else
          pv < /dev/zero -N "Writing zeros to \"$4\" volume" -pebs $3 | sudo dd of=/dev/$1 bs=$2 $ddargs 2> /dev/null
     fi
else
     (
     if [[ "$usezenity" == "true" ]]; then printf "# "; fi
     echo "Writing zeros to \"$4\" volume..."
     sudo dd if=/dev/zero of=/dev/$1 bs=$2 $ddargs 2> /dev/null
     if [[ "$usezenity" == "true" ]]; then echo "100"; fi
     ) | if [[ "$usezenity" == "true" ]]; then eval zenity $zenwipeargs; else cat; fi
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
        echo "Zeros are being written to $1 volume..."
        while kill -0 $BUFF_PID 2> /dev/null; do sleep 1; done
   fi
   if [[ "$usezenity" == "true" ]]; then echo "100"; fi
   } | if [[ "$usezenity" == "true" ]]; then eval zenity $zenprogargs --pulsate --auto-close; else cat; fi
   
   if ! kill -0 $BUFF_PID 2> /dev/null; then return; fi

   {
   while kill -0 $BUFF_PID 2> /dev/null; do
         if [[ "$usezenity" == "true" ]]; then
            echo "# Writing zeros to $1 volume..."  
         fi
         dirty=$(cat /proc/meminfo | grep Dirty | awk '{print $2}')
         bufpct=$(((($volume_size - ($dirty * 1024)) * 100) / $volume_size))
         if   [[ "$usezenity" == "true" ]]; then
              echo $bufpct
         else
              echo -ne "Writing zeros to $1 volume:" $bufpct"%"\\r
         fi
   done

   if   [[ "$usezenity" == "true" ]]; then
        echo 100
   else
        echo "Writing zeros to $1 volume: 100%"
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

umount_isovolume () {
if ! sudo -nv 2>/dev/null; then
   #Request credentials for unmount if expired.
   if   [[ "$usezenity" == "true" ]]; then
        echo "# Remove temporary mount point..."
        zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
   else
        echo "Remove temporary mount point (sudo required)..."
   fi
fi
sudo umount $1 && sudo rm -r $1
gio mount -d $2
}

mount_error () {
if   [[ "$usezenity" == "true" ]]; then
     zenity --error --title="Mount Error" --text="$mnterror"
else
     echo -e "${RED}$mnterror${NC}"
     echo
     read -p "Press any key to continue... "
fi
exit 1
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
              mkftargs+=(-u $spt -h $hds -v "$label")
              if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
              if [[ $fmtyp == "FULL" ]]; then
                 volume_size=$(diskutil info $drive's'$isopart | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                 zero_part $drive's'$isopart '4m' $volume_size "$label"
              fi
              if   [[ $verbose == "true" ]]; then
                   echo "Creating $fstyp file system on \"$label\" volume..."
                   echo $boarder
                   sudo newfs_msdos "${mkftargs[@]}" /dev/$drive's'$isopart
                   echo $boarder
              else
                   sudo newfs_msdos "${mkftargs[@]}" /dev/$drive's'$isopart > /dev/null
              fi
         elif [[ $fstyp == "EXFAT" ]]; then
              if [[ $hasgrub == "true" ]]; then efipart=2; else efipart=1; fi
              if [[ $hasgrub == "true" ]]; then isopart=3; else isopart=2; fi
              if [[ $fmtyp == "FULL" ]]; then
                 volume_size=$(diskutil info $drive's'$efipart | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                 zero_part $drive's'$efipart '4m' $volume_size GRUB
              fi
              mkgefiargs=(-u $spt -h $hds -F 32 -v GRUB)
              if   [[ $verbose == "true" ]]; then
                   echo "Creating FAT32 file system on GRUB volume..."
                   echo $boarder
                   sudo newfs_msdos "${mkgefiargs[@]}" /dev/$drive's'$efipart
                   echo $boarder
              else
                   sudo newfs_msdos "${mkgefiargs[@]}" /dev/$drive's'$efipart > /dev/null
              fi
              if [[ $fmtyp == "FULL" ]]; then
                 volume_size=$(diskutil info $drive's'$isopart | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                 zero_part $drive's'$isopart '4m' $volume_size "$label"
              fi
              if   [[ $verbose == "true" ]]; then
                   echo "Creating exFAT file system on \"$label\" volume..."
                   echo $boarder
                   sudo newfs_exfat -v "$label" /dev/$drive's'$isopart
                   echo $boarder
              else
                   sudo newfs_exfat -v "$label" /dev/$drive's'$isopart > /dev/null
              fi
              vsnbytes=$(sudo dd if=/dev/$drive's'$isopart skip=100 bs=1 count=4 2>/dev/null | hexdump -e '4/4 "%X"')
         fi
         if [[ "$persist" == "true" ]]; then
            if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
            if [[ $verbose == "false" ]]; then dspmode="-q"; fi
            mke2pstargs+=($dspmode)
            if   [[ "$overlay" == "true" ]]; then
                 if [[ $fmpst == "FULL"* ]]; then
                    diskutil zeroDisk short $drive's'$extpart > /dev/null
                 fi
                 if   [[ $verbose == "true" ]]; then
                      echo "Creating exFAT file system on $extlabel volume..."
                      echo $boarder
                      sudo newfs_exfat -v $extlabel /dev/$drive's'$extpart
                      echo $boarder
                 else
                      sudo newfs_exfat -v $extlabel /dev/$drive's'$extpart > /dev/null
                 fi
            else
                 if [[ $fmpst == "FULL"* || $verbose == "true" ]]; then
                    echo "Creating $fspst file system on $extlabel volume..."
                 fi
                 if [[ $verbose == "true" ]]; then echo $boarder; fi
                 diskutil zeroDisk short $drive's'$extpart > /dev/null
                 sudo mke2fs "${mke2pstargs[@]}" /dev/$drive's'$extpart
                 if [[ $verbose == "true" ]]; then echo $boarder; fi
            fi
            if [[ $datapartsz != "0"  ]]; then
               if [[ $hasgrub == "true" ]]; then fatpart=4; else fatpart=3; fi
               if   [[ "$datafs" == "FAT16" || "$datafs" == "FAT32" ]]; then
                    if [[ $fmtyp == "FULL" ]]; then
                       volume_size=$(diskutil info $drive's'$fatpart | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                       zero_part $drive's'$fatpart '4m' $volume_size DATA
                    fi
                    mkfdpargs=(-u $spt -h $hds -F ${datafs:3} -v DATA)
                    if   [[ $verbose == "true" ]]; then
                         echo "Creating $datafs file system on DATA volume..."
                         echo $boarder
                         sudo newfs_msdos "${mkfdpargs[@]}" /dev/$drive's'$fatpart
                         echo $boarder
                    else
                         sudo newfs_msdos "${mkfdpargs[@]}" /dev/$drive's'$fatpart > /dev/null
                    fi
               elif [[ "$datafs" == "EXFAT" ]]; then
                    if [[ $fmtyp == "FULL" ]]; then
                       volume_size=$(diskutil info $drive's'$fatpart | grep 'Disk Size:' | awk '{print $5}' | cut -c2-)
                       zero_part $drive's'$fatpart '4m' $volume_size DATA
                    fi
                    if   [[ $verbose == "true" ]]; then
                         echo "Creating exFAT file system on DATA volume..."
                         echo $boarder
                         sudo newfs_exfat -v DATA /dev/$drive's'$fatpart
                         echo $boarder
                    else
                         sudo newfs_exfat -v DATA /dev/$drive's'$fatpart > /dev/null
                    fi
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
                        elif [[ $databytes -le $(($mbyte * 500)) ]]; then
                             datapty=e; datafs="FAT16"
                        else
                             datapty=c; datafs="FAT32"
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
	          echo "5"; printf "# "
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
	  
	  if [[ "$usezenity" == "true" ]]; then echo "10"; printf "# "; fi
	  echo "Partition and format disk..."
	  if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	     zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	     if [[ $? -ne 0 ]]; then
	        echo "# Partitioning operation canceled."
                exit 1
	     fi
	  fi
	  if   [[ $prtshm == "MBR" ]]; then
	       if   [[ "$persist" == "true" ]]; then
	            sfdargs=(,$isopartsz'M',$pty,*\\n,$pstpart,L)
	            if [[ $datapartsz != "0"  ]]; then sfdargs+=(\\n,$datapartsz'M',$datapty); fi
	            echo -e "${sfdargs[@]}" | sudo sfdisk -W always /dev/$drive > /dev/null && sleep 1
	       elif [[ $fstyp == "EXT"* ]]; then
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
	       elif [[ $fstyp == "EXT"* ]]; then
	            sfdargs+=(size=50M,type=$pty,name='"'GRUB UEFI'"'\\n)
	            sfdargs+=(type=L,name='"'$label'"')
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       else
	            sfdargs+=(type=$pty,name='"'$label'"')
	            echo -e "${sfdargs[@]}" | sudo sfdisk --label gpt -W always /dev/$drive > /dev/null && sleep 1
	       fi
	  fi
	  fmtalert="false"
	  if [[ $verbose == "false" ]]; then dspmode="-q"; fi
	  if   [[ $fstyp == "EXT"* ]] ; then
	       mke2isoargs+=($dspmode)
	       if [[ $hasgrub == "true" ]]; then isopart=3; else isopart=2; fi
	       if [[ $fmtyp == "FULL"* || $verbose == "true" ]]; then
	          if [[ "$usezenity" == "true" ]]; then echo "15"; printf "# "; fi
	          echo "Creating $fstyp file system on \"$label\" volume..."
	       fi
	       if [[ $verbose == "true" ]]; then echo $boarder; fi
	       sudo mke2fs "${mke2isoargs[@]}" /dev/$drive"$isopart" | \
	       if [[ "$usezenity" == "true" && $verbose == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
	       if [[ $verbose == "true" ]]; then echo $boarder; fi
	       if [[ $hasgrub == "true" ]]; then efipart=2; else efipart=1; fi
	       mkgefiargs=(-F 32 -n GRUB)
	       if [[ ($fmtyp == "FULL"* || $verbose == "true") && "$usezenity" == "true" ]]; then echo "20"; printf "# "; fi
	       if [[ $fmtyp == "FULL"* ]]; then
	          sudo dd if=/dev/zero of=/dev/$drive"$efipart" bs=1M status=none 2> /dev/null
	          if [[ "$usezenity" == "true" && $verbose == "true" ]]; then fmtalert="true"; fi
	          echo "Checking GRUB volume for bad blocks..."
	          mkgefiargs+=(-c)
	       fi
	       if   [[ $verbose == "true" ]]; then
	            if [[ $fmtyp == "QUICK" ]]; then
	               echo "Creating FAT32 file system on GRUB volume..."
	            fi
	            mkgefiargs+=($dspmode)
	            echo $boarder
	            (if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	                zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	                if [[ $? -ne 0 ]]; then
	                   echo "# Format of GRUB volume canceled."
                           exit 1
	                fi
	            fi
	            sudo mkfs.fat "${mkgefiargs[@]}" /dev/$drive"$efipart" && \
	            if [[ "$fmtalert" == "true" ]]; then echo "Format completed successfully."; fi) | \
	            if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
	            echo $boarder
	       else
	            sudo mkfs.fat "${mkgefiargs[@]}" /dev/$drive"$efipart" > /dev/null
	       fi
	  else
	       if [[ ($fmtyp == "FULL"* || $verbose == "true") && "$usezenity" == "true" ]]; then echo "20"; printf "# "; fi
	       if [[ $hasgrub == "true" ]]; then isopart=2; else isopart=1; fi
	       mkftargs+=(-n "$label")
	       if [[ $fmtyp == "FULL" ]]; then
	          volume_size=$(sudo blockdev --getsize64 /dev/$drive"$isopart")
                  zero_part $drive"$isopart" '4M' $volume_size "$label"
                  if [[ "$usezenity" == "true" && $verbose == "true" ]]; then fmtalert="true"; fi
                  echo "Checking \"$label\" volume for bad blocks..."
               fi
               if   [[ $verbose == "true" ]]; then
                    if [[ $fmtyp == "QUICK" ]]; then
	               echo "Creating $fstyp file system on \"$label\" volume..."
	            fi
                    echo $boarder
                    (if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	                zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	                if [[ $? -ne 0 ]]; then exit 1; fi
	            fi
	            sudo mkfs.fat "${mkftargs[@]}" /dev/$drive"$isopart" && \
	            if [[ "$fmtalert" == "true" ]]; then echo "Format completed successfully."; fi) | \
                    if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
                    echo $boarder
               else
	            sudo mkfs.fat "${mkftargs[@]}" /dev/$drive"$isopart" > /dev/null
	       fi
	  fi
	  if [[ "$persist" == "true" ]]; then
	     mke2pstargs+=($dspmode)
	     if [[ $hasgrub == "true" ]]; then extpart=3; else extpart=2; fi
	     if [[ $fmpst == "FULL"* || $verbose == "true" ]]; then
	        if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	        echo "Creating $fspst file system on $extlabel volume..."
	     fi
	     if [[ $verbose == "true" ]]; then echo $boarder; fi
	     sudo mke2fs "${mke2pstargs[@]}" /dev/$drive"$extpart" | \
	     if [[ "$usezenity" == "true" && $verbose == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
	     if [[ $verbose == "true" ]]; then echo $boarder; fi
	     if [[ $datapartsz != "0" ]]; then
	        if [[ $hasgrub == "true" ]]; then fatpart=4; else fatpart=3; fi
	        volume_size=$(sudo blockdev --getsize64 /dev/$drive"$fatpart")
	        if   [[ "$datafs" == "FAT16" || "$datafs" == "FAT32" ]]; then
	             if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	             mkfdpargs=(-F ${datafs:3} -n DATA)
	             if [[ $fmtyp == "FULL"* ]]; then
                        zero_part $drive"$fatpart" '4M' $volume_size 'DATA'
                        if [[ "$usezenity" == "true" && $verbose == "true" ]]; then fmtalert="true"; fi
                        echo "Checking DATA volume for bad blocks..."
                        mkfdpargs+=(-c)
                     fi
                     if   [[ $verbose == "true" ]]; then
                          if [[ $fmtyp == "QUICK" ]]; then
	                     echo "Creating $datafs file system on DATA volume..."
	                  fi
                          mkfdpargs+=($dspmode)
                          echo $boarder
                          (if [[ "$usezenity" == "true" && ! -t 0 ]]; then
	                      zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	                      if [[ $? -ne 0 ]]; then
	                         echo "# Format of DATA volume canceled."
                                 exit 1
	                      fi
	                  fi
	                  sudo mkfs.fat "${mkfdpargs[@]}" /dev/$drive"$fatpart" && \
	                  if [[ "$fmtalert" == "true" ]]; then echo "Format completed successfully."; fi) | \
                          if [[ "$usezenity" == "true" ]]; then eval zenity $zenvfmtargs; else cat; fi
                          echo $boarder
                     else
	                  sudo mkfs.fat "${mkfdpargs[@]}" /dev/$drive"$fatpart" > /dev/null
	             fi
	        elif [[ "$datafs" == "EXFAT" ]]; then
	             mkexfdpargs=($dspmode -L DATA)
	             if [[ $fmtyp == "FULL"* ]]; then
	                mkexfdpargs+=(-f)
	                if [[ $verbose == "true" ]]; then
	                   vbfmtinfo=$(mktemp -t vbfmtout.XXXXXXX)
	                fi
	             fi
	             if   [[ $fmtyp == "FULL" && $verbose == "true" ]]; then
                          coproc BUFF (sudo mkfs.exfat "${mkexfdpargs[@]}" /dev/$drive"$fatpart") > "$vbfmtinfo"
                     else
                          coproc BUFF (sudo mkfs.exfat "${mkexfdpargs[@]}" /dev/$drive"$fatpart")
                     fi
                     if [[ ($fmtyp == "FULL" && "$usezenity" == "true") ||
                           ($fmtyp == "QUICK" && $verbose == "true") ]]; then
                        if [[ "$usezenity" == "true" ]]; then printf "# "; fi
                        echo "Creating exFAT file system on DATA volume..."
                     fi
                     if [[ $fmtyp == "FULL" ]]; then show_progress 'DATA'; fi
                     if [[ $verbose == "true" ]]; then display_verbose; fi
                     if [[ $fmtyp == "QUICK" && $verbose == "false" ]]; then wait $BUFF_PID; fi
	        fi
	     fi
	  fi
	  if [[ "$usezenity" == "true" ]]; then echo "25"; printf "# "; fi
	  echo "Mount boot disk..." && sleep 1
	  mnterror="N/A"
	  if   [[ -d "/media/$USER" ]]; then
	       media_path="/media/$USER"
	  elif [[ -d "/run/media/$USER" ]]; then
	       media_path="/run/media/$USER"
	  fi
	  if [[ "$usezenity" == "true" ]]; then
	     if ! sudo -nv 2>/dev/null; then
	        zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	        if [[ $? -ne 0 ]]; then
	           echo "# Disk mounting operation canceled."
	           exit 1
	        fi
	     fi
	  fi
	  if   [[ $fstyp == "EXT"* ]] ; then
	       if   gio mount -d /dev/$drive"$efipart"; then
	            if   gio mount -d /dev/$drive"$isopart"; then
	                 isovolpath="$media_path/$label"
	                 sudo chmod -R 777 "$isovolpath"
	            else
	                 mnterror="Failed to mount \"$label\" volume."
	            fi
	       else
	            mnterror="Failed to mount GRUB volume."
	       fi
	  else
	       sudo mkdir $isovolpath
	       if ! sudo mount -o $isovolopts /dev/$drive"$isopart" $isovolpath; then
	          mnterror="Failed to mount \"$label\" volume."
	          sudo rm -f $isovolpath
	       fi
	  fi
	  if [[ "$mnterror" != "N/A"  ]]; then mount_error; fi
	  if [[ "$persist" == "true" ]]; then
	     if   gio mount -d /dev/$drive"$extpart"; then
	          if [[ $datapartsz != "0"  ]]; then
	             if ! gio mount -d /dev/$drive"$fatpart"; then
	                if   [[ "$usezenity" == "true" ]]; then
                             zenity --warning --title="Mount Failure" --text="Unable to mount DATA volume."
	                else
	                     echo -e "${YELLOW}Failed to mount DATA volume.${NC}"
	                fi
	             fi
	          fi
	     else
	          mnterror="Failed to mount \"$extlabel\" volume."; mount_error
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
	     umount_isovolume $isovolpath /dev/$drive"$isopart"
	  fi
	  isolinuxdir=$(get_syslinux_path "$media_path/$label" isolinux)
	  syslinuxdir=$(get_syslinux_path "$media_path/$label" syslinux)
	  if   [[ ! -z "$isolinuxdir" && ! -z "$syslinuxdir" ]]; then
	       if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	       echo "Remove unneeded isolinux files..."
	       rm -r "$isolinuxdir"
	  elif [[ ! -z "$isolinuxdir" && -z "$syslinuxdir" ]]; then
	       if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	       rename_isolinux "$(dirname "$isolinuxdir")"
	  fi
	  if [[ $fstyp == "EXT"* && -f "$media_path/$label/$efigrubcfg" ]]; then
	     if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	     mkgrubefi "$media_path/$label" "$media_path/GRUB"
	  fi
	  if [[ "$usblabel" == "true" ]]; then
	     if [[ "$usezenity" == "true" ]]; then printf "# "; fi
	     update_cdlabel "$media_path/$label"
	  fi
	  if [[ "$persist" == "true" ]]; then
	     if  [[ "$pupsave" == "true" ]]; then
	         if [[ "$usezenity" == "true" ]]; then echo "60"; fi
                 echo "SS_ID=$extlabel" > "$media_path/$label/SAVESPEC"
             else
                 config_persist "$media_path/$label" "$media_path/$extlabel" "1M"
             fi
	  fi
	  if [[ -f "$media_path/$label/md5sum.txt" ]]; then
	     if [[ "$usezenity" == "true" ]]; then echo "90"; printf "# "; fi
	     checksum_files "$media_path/$label" md5sum sha256sum
	  fi
	  if [[ -f "$media_path/$label/sha256sum.txt" ]]; then
	     if [[ "$usezenity" == "true" ]]; then echo "95"; printf "# "; fi
	     checksum_files "$media_path/$label" sha256sum md5sum
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
      if [[ $format == "vfat" ]]; then
         umount $device
         sudo mkdir $ufdvolpath
	 sudo mount -o $ufdvolopts $device $ufdvolpath
      fi
      extract_files "$isofile" "$ufdvolpath" "0" "1"
      if [[ $format == "vfat" ]]; then
         umount_isovolume $ufdvolpath $device
      fi
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
