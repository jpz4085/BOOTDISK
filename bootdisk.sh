#!/usr/bin/env bash

#  bootdisk.sh - menus and options
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

title_block () {
cat<<EOF
===========================
   ---BOOTDISK v1.8---
Flash Drive Formatting Tool
===========================
Select an option:

EOF
}

lower_border () {
cat<<EOF
===========================
EOF
}

menu_full () {
while :
do
clear
title_block
cat<<EOF
FreeDOS 1.3  (1)
MS-DOS  8.0  (2)
Windows 7-11 (3)
Linux/Other  (4)
Tools Menu   (5)
About        (6)
Quit         (7)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  msdosdisk   ;;
"3")  windowsmode ;;
"4")  linux_other ;;
"5")  menu_tools  ;;
"6")  show_about  ;;
"7")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_standard () {
while :
do
clear
title_block
cat<<EOF
FreeDOS 1.3  (1)
Windows 7-11 (2)
Linux/Other  (3)
Tools Menu   (4)
About        (5)
Quit         (6)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  windowsmode ;;
"3")  linux_other ;;
"4")  menu_tools  ;;
"5")  show_about  ;;
"6")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_default () {
while :
do
clear
title_block
cat<<EOF
Windows 7-11 (1)
Linux/Other  (2)
Tools Menu   (3)
About        (4)
Quit         (5)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  windowsmode ;;
"2")  linux_other ;;
"3")  menu_tools  ;;
"4")  show_about  ;;
"5")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_tools () {
while :
do
clear
title_block
cat<<EOF
Extract MS-DOS 8.0          (1)
Download an ISO file        (2)
Verify Windows ISO checksum (3)
Custom Windows installation (4)
Return to Main Menu         (5)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  extractdos  ;;
"2")  fido_script ;;
"3")  checksum    ;;
"4")  customize   ;;
"5")  break       ;;
 * )  select_err  ;;
esac
done
}

fdosdisk () {
clear
echo "   FreeDOS 1.3 Boot Disk Script    "
echo "-----------------------------------"
if [[ "$system" == "Darwin" ]]; then
   read -p "Enter target disk [disk#]: " tgtdsk
   while [[ $tgtdsk != *"disk"* ]]; do
         echo -e "${RED}Invalid disk name. Try again.${NC}"
         read -p "Enter target disk [disk#]: " tgtdsk
   done
elif [[ "$system" == "Linux" ]]; then
     read -p "Enter target disk [sd*]: " tgtdsk
     while [[ $tgtdsk != *"sd"* ]]; do
           echo -e "${RED}Invalid disk name. Try again.${NC}"
           read -p "Enter target disk [sd*]: " tgtdsk
     done
fi

read -p "Enter file system [FAT16/FAT32]: " fstyp
fstyp=${fstyp^^}
while [[ $fstyp != "FAT16" && $fstyp != "FAT32" ]]; do
    echo -e "${RED}Invalid file system type. Try again.${NC}"
    read -p "Enter file system [FAT16/FAT32]: " fstyp
    fstyp=${fstyp^^}
done

read -p "Enter label [FREEDOS]: " volname
if [[ "$volname" == "" ]]; then volname=FREEDOS; fi
volname=${volname^^}
n=${#volname}
while [ $n -gt 11 ]; do
      echo -e "${RED}Label must be eleven characters or less.${NC}"
      read -p "Enter label [WINDOWS]: " volname
      n=${#volname}
done

echo
(cd $resdir/FreeDOS; ./freedosdisk.sh $system $fstyp "$volname" $tgtdsk)
}

msdosdisk () {
clear
echo "    MS-DOS 8.0 Boot Disk Script    "
echo "-----------------------------------"
if [[ "$system" == "Darwin" ]]; then
   read -p "Enter target disk [disk#]: " tgtdsk
   while [[ $tgtdsk != *"disk"* ]]; do
         echo -e "${RED}Invalid disk name. Try again.${NC}"
         read -p "Enter target disk [disk#]: " tgtdsk
   done
elif [[ "$system" == "Linux" ]]; then
     read -p "Enter target disk [sd*]: " tgtdsk
     while [[ $tgtdsk != *"sd"* ]]; do
           echo -e "${RED}Invalid disk name. Try again.${NC}"
           read -p "Enter target disk [sd*]: " tgtdsk
     done
fi

read -p "Enter file system [FAT16/FAT32]: " fstyp
fstyp=${fstyp^^}
while [[ $fstyp != "FAT16" && $fstyp != "FAT32" ]]; do
    echo -e "${RED}Invalid file system type. Try again.${NC}"
    read -p "Enter file system [FAT16/FAT32]: " fstyp
    fstyp=${fstyp^^}
done

read -p "Enter label [MSDOS80]: " volname
if [[ "$volname" == "" ]]; then volname=MSDOS80; fi
volname=${volname^^}
n=${#volname}
while [ $n -gt 11 ]; do
      echo -e "${RED}Label must be eleven characters or less.${NC}"
      read -p "Enter label [MSDOS80]: " volname
      n=${#volname}
done

echo
(cd $resdir/MS-DOS; ./msdosdisk.sh $system $fstyp "$volname" $tgtdsk)
}

windowsmode () {
wtgsupport="false"
if   [[ "$system" == "Darwin" ]]; then
     personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
     if  [[ $personality == "Tuxera" || $personality == "UFSD_NTFS" ||
         (! -z $(command -v mkntfs) && ! -z $(command -v ntfs-3g)) ]]; then
         if [[ $wimtools == "true" && ! -z $(command -v bcd-sys) ]]; then
            wtgsupport="true"
         fi
     fi
elif [[ "$system" == "Linux" ]]; then
     if [[ -z "$winfsopts" ]]; then
        if [[ ! -z $(command -v mkfs.exfat) ]]; then winfsopts+="/EXFAT"; fi
        if [[ ! -z $(command -v mkntfs) ]]; then winfsopts+="/NTFS"; fi
     fi
     if [[ ! -z $(command -v mkntfs) && ! -z $(command -v ntfs-3g) ]]; then
        if [[ $wimtools == "true" && ! -z $(command -v bcd-sys) ]]; then
           wtgsupport="true"
        fi
     fi
fi
if   [[ $wtgsupport == "true" ]]; then
     while :
     do
     clear
     title_block
     echo "Create install media    (1)"
     echo "Create Windows to Go    (2)"
     echo "Return to Main Menu     (3)"
     lower_border
     read -p"Enter Choice: "
     case "$REPLY" in
     "1")  windowsdisk ;;
     "2")  windowstogo ;;
     "3")  break       ;;
      * )  select_err  ;;
     esac
     done
else
     windowsdisk
fi
}

windowsdisk () {
clear
echo "    Windows Install Disk Script    "
echo "-----------------------------------"
if [[ "$system" == "Darwin" ]]; then
   read -p "Enter target disk [disk#]: " tgtdsk
   while [[ $tgtdsk != *"disk"* ]]; do
         echo -e "${RED}Invalid disk name. Try again.${NC}"
         read -p "Enter target disk [disk#]: " tgtdsk
   done
elif [[ "$system" == "Linux" ]]; then
     read -p "Enter target disk [sd*]: " tgtdsk
     while [[ $tgtdsk != *"sd"* ]]; do
           echo -e "${RED}Invalid disk name. Try again.${NC}"
           read -p "Enter target disk [sd*]: " tgtdsk
     done
fi

read -p "Enter partition scheme [GPT/MBR]: " prtshm
prtshm=${prtshm^^}
while [[ $prtshm != "GPT" && $prtshm != "MBR" ]]; do
      echo -e "${RED}Invalid partition scheme. Try again.${NC}"
      read -p "Enter partition scheme [GPT/MBR]: " prtshm
      prtshm=${prtshm^^}
done

if   [[ "$system" == "Darwin" ]]; then
     if  [[ $personality == "Tuxera" || $personality == "UFSD_NTFS" ]]; then
         read -p "Enter file system [FAT32/EXFAT/NTFS]: " fstyp
         fstyp=${fstyp^^}
         while [[ $fstyp != "FAT32" && $fstyp != "EXFAT" && $fstyp != "NTFS" ]]; do
               echo -e "${RED}Invalid file system type. Try again.${NC}"
               read -p "Enter file system [FAT32/EXFAT/NTFS]: " fstyp
               fstyp=${fstyp^^}
         done
     else
         read -p "Enter file system [FAT32/EXFAT]: " fstyp
         fstyp=${fstyp^^}
         while [[ $fstyp != "FAT32" && $fstyp != "EXFAT" ]]; do
               echo -e "${RED}Invalid file system type. Try again.${NC}"
               read -p "Enter file system [FAT32/EXFAT]: " fstyp
               fstyp=${fstyp^^}
         done
     fi
elif [[ "$system" == "Linux" ]]; then
    if   [[ "$winfsopts" != "" ]]; then
         read -p "Enter file system [FAT32$winfsopts]: " fstyp
    else
         fstyp="FAT32"
         echo "Only file system available is FAT32."
    fi
    fstyp=${fstyp^^}
    while [[ $fstyp != "FAT32" && $fstyp != "EXFAT" && $fstyp != "NTFS" ]]; do
        echo -e "${RED}Invalid file system type. Try again.${NC}"
        read -p "Enter file system [FAT32/EXFAT/NTFS]: " fstyp
        fstyp=${fstyp^^}
    done
fi
    
if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]] && [[ -e $resdir/Support/uefi-ntfs.img ]]; then
    read -p "Enable UEFI boot support [Y/N]? " uefint
    uefint=${uefint^^}
    while [[ $uefint != "Y" && $uefint != "N" ]]; do
        echo -e "${RED}Invalid entry. Try again.${NC}"
        read -p "Enable UEFI boot support [Y/N]? " uefint
        uefint=${uefint^^}
    done
else
    uefint="N"
fi

read -p "Enter label [WINDOWS]: " volname
n=${#volname}
if [[ $fstyp == "FAT32" || $fstyp == "EXFAT" ]]; then
   if [[ $fstyp == "FAT32" ]]; then volname=${volname^^}; fi
   while [ $n -gt 11 ]; do
         echo -e "${RED}Label must be eleven characters or less.${NC}"
         read -p "Enter label [WINDOWS]: " volname
         n=${#volname}
   done
elif [[ "$system" == "Linux" && $fstyp == "NTFS" ]]; then
     while [ $n -gt 128 ]; do
           echo -e "${RED}Label must be 128 characters or less.${NC}"
           read -p "Enter label [WINDOWS]: " volname
           n=${#volname}
     done
fi
if [[ "$volname" == "" ]]; then volname=WINDOWS; fi
read -p "Enter ISO path [NONE]: " image
if [[ "$image" == "" ]]; then image=NONE; fi

echo
(cd $resdir/Windows; ./windowsdisk.sh $system $prtshm $fstyp $uefint "$volname" "$image" $wimtools $tgtdsk)
}

wtgtitle () {
clear
echo "      Windows to Go Script      "
echo "--------------------------------"
}

windowstogo () {
wtgtitle
if [[ "$system" == "Darwin" ]]; then
   read -p "Enter target disk [disk#]: " tgtdsk
   while [[ $tgtdsk != *"disk"* ]]; do
         echo -e "${RED}Invalid disk name. Try again.${NC}"
         read -p "Enter target disk [disk#]: " tgtdsk
   done
elif [[ "$system" == "Linux" ]]; then
     read -p "Enter target disk [sd*]: " tgtdsk
     while [[ $tgtdsk != *"sd"* ]]; do
           echo -e "${RED}Invalid disk name. Try again.${NC}"
           read -p "Enter target disk [sd*]: " tgtdsk
     done
fi
read -p "Enter path to ISO file: " image
while [[ ! -f "$image" || "$image" != *.iso ]]; do
      echo -e "${RED}Invalid file. Please try again.${NC}"
      read -p "Enter path to ISO file: " image
done
echo "Mount install disk image..."
if   [[ "$system" == "Darwin" ]]; then
     wimfile="/tmp/isomount/sources/install.wim"
     hdiutil attach "$image" -mountpoint /tmp/isomount -nobrowse > /dev/null
elif [[ "$system" == "Linux" ]]; then
     wimfile="/mnt/isomount/sources/install.wim"
     if [[ ! -f $wimfile ]]; then
        sudo mkdir -p /mnt/isomount
        sudo mount -o loop "$image" /mnt/isomount
     fi
fi
if [[ ! -f $wimfile ]]; then
   echo -e "${RED}Unable to find install archive in DVD image.${NC}"
   echo
   read -p "Press any key to continue... " -n1 -s
   return 1
fi

wtgtitle
idxnum=$(wiminfo $wimfile | grep -E '^(Index:)' | cut -d " " -f2- | sed 's/^[[:space:]]*//g;s/[0-9]$/&\./g')
prodname=$(wiminfo $wimfile | grep -E '^(Name:)' | cut -d " " -f2- | sed 's/^[[:space:]]*//g')
echo "Windows products on $(basename "$image")"
paste <(printf %s "$idxnum") <(printf %s "$prodname")
read -p "Enter Choice (q to Quit): " index
while [[ $idxnum != *$index* && $index != "q" ]]; do
      echo -e "${RED}Invalid entry. Please try again.${NC}"
      read -p "Enter Choice: " index
done

if [[ "$index" != "q" ]]; then
   echo
   (cd $resdir/Windows; ./windowstogo.sh $system $wimfile $index $tgtdsk)
fi

if [[ ! $? -eq 0 ]]; then wtgerror="true"; else wtgerror="false"; fi
rm -f /tmp/wimfile_errors.txt
echo "Unmount install disk image..."
if   [[ "$system" == "Darwin" ]]; then
     hdiutil detach /tmp/isomount > /dev/null
elif [[ "$system" == "Linux" ]]; then
     sudo umount /mnt/isomount && sudo rm -d /mnt/isomount
fi
if  [[ $wtgerror == "true" ]]; then
    echo
    read -p "Press any key to continue... " -n1 -s
else
    echo "Finished!"
    sleep 2
fi
}

linux_other () {
clear
echo "      Linux and Other Script      "
echo "----------------------------------"
wipedisk="false"
ddmode="false"
datapart="false"
prtshm="CURRENT"
pstpart="N/A"
fstyp="N/A"
volname="N/A"
fmtopts="FAT16/FAT32"
ubtdistrolist="elementary|Ubuntu|Mint|Pop_OS|Zorin|neon"
pstcompatlist="$ubtdistrolist|d-live|Fedora|CDROM|gentoo"
read -p "Enter path to file: " image
while [[ ! -f "$image" ]]; do
      echo -e "${RED}Unable to access image file. Try again.${NC}"
      read -p "Enter path to file: " image
done
if   [[ "$image" == *".iso"* ]]; then
     if   [[ "$system" == "Darwin" ]]; then
          isodevinfo=$(hdiutil attach -nomount "$image" | head -n1)
          isoblkdev=$(echo "$isodevinfo" | awk '{print $1}')
          prtable=$(echo "$isodevinfo" | awk '{print $2}')
          hdiutil detach $isoblkdev > /dev/null
     elif [[ "$system" == "Linux" ]]; then
          prtable=$(fdisk -l "$image" 2> /dev/null | grep 'Disklabel type:')
     fi
     if [[ ! -z "$prtable" ]]; then hybridiso="true"; else hybridiso="false"; fi
     if [[ "$hybridiso" == "true" ]]; then
        read -p "Write image using the dd utility [Y/N]? " ddwrite
        ddwrite=${ddwrite^^}
        while [[ $ddwrite != "Y" && $ddwrite != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Write image using the dd utility [Y/N]? " ddwrite
              ddwrite=${ddwrite^^}
        done
        if [[ "$ddwrite" == "Y" ]]; then prtshm="ERASE"; ddmode="true"; fi
     fi
     if [[ "$hybridiso" == "false" || "$ddmode" == "false" ]]; then
        read -p "Wipe disk before extracting files [Y/N]? " wipe
        wipe=${wipe^^}
        while [[ $wipe != "Y" && $wipe != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Wipe disk before extracting files [Y/N]? " wipe
              wipe=${wipe^^}
        done
        if [[ $wipe == "Y" ]]; then wipedisk="true"; fi
     fi
else
     prtshm="ERASE"
fi

if  [[ "$wipedisk" == "true" || "$prtshm" == "ERASE" ]]; then
    if [[ "$system" == "Darwin" ]]; then
    read -p "Enter target disk [disk#]: " target
    while [[ $target != *"disk"* ]]; do
          echo -e "${RED}Invalid disk name. Try again.${NC}"
          read -p "Enter target disk [disk#]: " target
    done
    elif [[ "$system" == "Linux" ]]; then
         read -p "Enter target disk [sd*]: " target
         while [[ $target != *"sd"* ]]; do
               echo -e "${RED}Invalid disk name. Try again.${NC}"
               read -p "Enter target disk [sd*]: " target
         done
    fi
    if [[ "$wipedisk" == "true" ]]; then
       read -p "Enter partition scheme [GPT/MBR]: " prtshm
       prtshm=${prtshm^^}
       while [[ $prtshm != "GPT" && $prtshm != "MBR" ]]; do
             echo -e "${RED}Invalid partition scheme. Try again.${NC}"
             read -p "Enter partition scheme [GPT/MBR]: " prtshm
             prtshm=${prtshm^^}
       done
       if file "$image" | grep -qiE "MX-Live"; then
          if   [[ "$system" == "Darwin" ]]; then
               fmtopts+="/EXFAT"
          elif [[ "$system" == "Linux" ]]; then
               fmtopts+="/EXT4"
          fi
       fi
       read -p "Enter file system [$fmtopts]: " fstyp
       fstyp=${fstyp^^}
       while [[ $fstyp != "FAT16" && $fstyp != "FAT32" && 
                $fstyp != "EXT4" && $fstyp != "EXFAT" ]]; do
             echo -e "${RED}Invalid file system type. Try again.${NC}"
             read -p "Enter file system [$fmtopts]: " fstyp
             fstyp=${fstyp^^}
       done
       shopt -s extglob
       volname=$(file "$image" | awk -F"'" '{for (i=2; i<=NF; i+=2) print $i}' | head -c 11)
       volname=${volname//[\*\?\/\\\|\,\;\:\+\=\<\>\[\]\"\.]/}
       volname=${volname##*( )}
       volname=${volname%%*( )}
       volname=${volname^^}
       read -p "Enter label [$volname]: " newvolname
       if [[ ! -z "$newvolname" ]]; then
          n=${#newvolname}
          while [ $n -gt 11 ]; do
                echo -e "${RED}Label must be eleven characters or less.${NC}"
                read -p "Enter label [$volname]: " newvolname
                n=${#newvolname}
          done
          volname="$newvolname"
          volname=${volname^^}
       fi
       if file "$image" | grep -qiE "$pstcompatlist"; then
          if   [[ ! -z $(command -v mkfs.ext4) ]]; then
               read -p "Enter size of persistent partition [0M]: " pstpartsz
               if [[ ! -z "$pstpartsz" ]]; then
                  pstpartsz=${pstpartsz^^}
                  if   [[ "$pstpartsz" == "MAX" ]]; then
                       if   [[ "$system" == "Darwin" ]]; then
                            pstpart="END"
                       elif [[ "$system" == "Linux" ]]; then
                            pstpart="+"
                       fi
                  else
                       while [[ ! ${pstpartsz%?} =~ ^[0-9]+$ || ! ${pstpartsz: -1} =~ [KMGT] ]]; do
                             echo -e "${RED}Invalid partition size. Try again.${NC}"
                             read -p "Enter size of persistent partition [0M]: " pstpartsz
                             if   [[ ! -z "$pstpartsz" ]]; then
                                  pstpartsz=${pstpartsz^^}
                                  if [[ "$pstpartsz" == "MAX" ]]; then
                                     if   [[ "$system" == "Darwin" ]]; then
                                          pstpart="END"
                                     elif [[ "$system" == "Linux" ]]; then
                                          pstpart="+"
                                     fi
                                     break
                                  fi
                             else
                                  break
                             fi
                       done
                       if [[ ! -z "$pstpartsz" && ${pstpartsz%?} != "0" && "$pstpartsz" != "MAX" ]]; then
                          pstpart="$pstpartsz"
                          read -p "Would you like to create a data partition [Y/N]? " mkdataprt
                          mkdataprt=${mkdataprt^^}
                          while [[ $mkdataprt != "Y" && $mkdataprt != "N" ]]; do
                                echo -e "${RED}Invalid entry. Try again.${NC}"
                                read -p "Would you like to create a data partition [Y/N]? " mkdataprt
                                mkdataprt=${mkdataprt^^}
                          done
                          if [[ $mkdataprt == "Y" ]]; then datapart="true"; fi
                       fi
                  fi
               fi
          elif file "$image" | grep -qiE "$ubtdistrolist"; then
               read -p "Allow linux to use the remaining space for persistence [Y/N]? " enablepst
               enablepst=${enablepst^^}
               while [[ $enablepst != "Y" && $enablepst != "N" ]]; do
                     echo -e "${RED}Invalid entry. Try again.${NC}"
                     read -p "Allow linux to use the remaining space for persistence [Y/N]?  " enablepst
                     enablepst=${enablepst^^}
               done
               if [[ $enablepst == "Y" ]]; then pstpart="deferred"; fi
          fi
       fi
    fi
else
    if [[ "$system" == "Darwin" ]]; then
       read -p "Enter path to disk [/Volumes/Untitled]: " target
    elif [[ "$system" == "Linux" ]]; then
         read -p "Enter path to disk [/media/user/USBDISK]: " target
    fi
fi

echo
(cd $resdir/Support; ./linuxotherdisk.sh $system "$image" "$target" $prtshm $pstpart $datapart $fstyp "$volname")
}

fido_title () {
clear
echo "  Download an ISO file using Fido  "
echo "-----------------------------------"
}

fido_script () {
fido_title
# Download script if missing or not current version then patch for Unix platforms.
fido_url="https://github.com/pbatard/Fido/releases/latest"
fido_url_ver=$(curl -IkLs -o /dev/null -w %{url_effective} $fido_url | grep -o "[^/]*$"| sed "s/v//g")
if [[ ! -e $resdir/Support/Fido.ps1 || "$(grep "# Fido v" $resdir/Support/Fido.ps1 | tr -d [:alpha:]  | awk '{print $2}')" != "$fido_url_ver" ]]; then
   rm -f $resdir/Support/Fido.* 2> /dev/null && curl -Lo $resdir/Support/Fido.ps1.lzma $fido_url/download/Fido.ps1.lzma 2> /dev/null
   7z e $resdir/Support/Fido.ps1.lzma -o$resdir/Support/ > /dev/null
   perl -i -pe's/\$version = 0.0/\$version = 10.0/' $resdir/Support/Fido.ps1 # Return the equivalent of Windows 10 by default.
   perl -i -pe's/"en-us"; Id = 0/"en-us"; Id = 1/' $resdir/Support/Fido.ps1  # Set language Id to one for UEFI Shell downloads.
   perl -i -pe's/curl/Invoke-WebRequest/' $resdir/Support/Fido.ps1 # Switch back to Invoke-WebRequest for Unix compatibility.
   # Use Invoke-WebRequest for ISO downloads on Unix.
   perl -i -pe's/Start-BitsTransfer.*/Invoke-WebRequest -UseBasicParsing -TimeoutSec \$DefaultTimeout -Uri \$Url -OutFile \$File/' $resdir/Support/Fido.ps1
   perl -i -pe's/Get-CimInstance.*/uname -m/' $resdir/Support/Fido.ps1 # Use uname to get machine architecture on Unix.
   perl -i -pe's/switch\(\$Arch\)/switch -Wildcard \(\$Arch\)/' $resdir/Support/Fido.ps1 # Use wildcards for matching values.
   # Change architecture values to match uname output.
   perl -i -pe's/0  \{/\"i\*86\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/1  \{/\"mips\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/2  \{/\"alpha\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/3  \{/\"ppc\*\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/5  \{/\"arm32\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/6  \{/\"ia64\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/9  \{/\"x86_64\"  \{/' $resdir/Support/Fido.ps1
   perl -i -pe's/12 \{/\"arm64\" \{/' $resdir/Support/Fido.ps1
fi
# Choose to step through the script or provide all arguments.
fido_mode="select"
while [[ "$fido_mode" != "step" && "$fido_mode" != "cmds" ]]; do
fido_title
echo "Please select how to run the script:"
echo " - Interactive Mode  (1)"
echo " - CommandLine Mode  (2)"
read -p "Please enter your choice to proceed: "
case "$REPLY" in
     "1")  fido_mode="step" ;;
     "2")  fido_mode="cmds" ;;
      * )  select_err  ;;
esac
done
# Check if PowerShell is supported and run script.
version=$(pwsh -Version | awk '{print $NF}')
fido_prompt="Please enter your choice (q to Quit): "
if  [ "$(printf '%s\n' "3.0" "$version" | sort -V | head -n1)" = "3.0" ]; then
    if   [[ "$fido_mode" == "step" ]]; then
         fido_title
         pwsh $resdir/Support/Fido.ps1 -Win List
         read -p "$fido_prompt" winver
         if [[ "$winver" == "q" ]]; then return; fi
         fido_title
         pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel List
         read -p "$fido_prompt" release
         if [[ "$release" == "q" ]]; then return; fi
         fido_title
         pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed List
         read -p "$fido_prompt" edition
         if [[ "$edition" == "q" ]]; then return; fi
         fido_title
         pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang List
         read -p "$fido_prompt" lang
         if [[ "$lang" == "q" ]]; then return; fi
         fido_title
         pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang $lang -Arch List
         read -p "$fido_prompt" arch
         if [[ "$arch" == "q" ]]; then return; fi
         fido_title
         cd ~/Downloads
         pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang $lang -Arch $arch
         sleep 1
         cd -
    elif [[ "$fido_mode" == "cmds" ]]; then
         fido_title
         read -p "Enter script arguments (q to Quit): " fido_args
         if [[ "$fido_args" == "q" ]]; then return; fi
         fido_title
         cd ~/Downloads
         pwsh $resdir/Support/Fido.ps1 $fido_args
         sleep 1
         cd -
    fi
else
    fido_title
    echo "PowerShell version 3.0 or higher required."
    echo
    read -n 1 -s -r -p "Press any key to continue"
fi
}

checksum () {
clear
echo "     Verify SHA-1 checksum of an ISO file     "
echo "----------------------------------------------"
read -p "Enter path to Windows ISO file: " file
echo "Calculating checksum..."
isosum=$(shasum "$file" | awk '{print $1}')
echo "Searching on adguard.net..."
python3 -m webbrowser "https://sha1.rg-adguard.net/search.php?sha1=$isosum"
read -p "Press any key to continue... " -n1 -s
}

extractdos () {
clear
echo "     Extract MS-DOS 8.0 files     "
echo "----------------------------------"
read -p "Enter path to diskcopy.dll: " file
echo
(cd $resdir/Support; ./extract_msdos.sh "$file")
}

customize () {
clear
echo "    Customize your Windows Installation    "
echo "-------------------------------------------"
if   [[ "$system" == "Darwin" ]]; then
     read -p "Enter path to Windows disk [/Volumes/Windows]: " windisk
elif [[ "$system" == "Linux" ]]; then
     read -p "Enter path to Windows disk [/media/$USER/Windows]: " windisk
fi
   
if [[ ! -d $windisk ]]; then
   echo
   echo "Unable to access path:" $windisk
   echo
   read -p "Press any key to continue... " -n1 -s
   return 1
fi

if   [[ -f "$windisk/sources/boot.wim" ]]; then
     winmedia="install"
elif [[ -f "$windisk/Windows/Boot/EFI/bootmgfw.efi" ]]; then
     winmedia="wintogo"
else
     echo
     echo "Unable to locate the Windows files."
     echo
     read -p "Press any key to continue... " -n1 -s
     return 1
fi

unsupported="false"
bypassnro="false"
# Check for Windows 11 media and provide options to disable hardware and Microsoft account requirements.
if   [[ $winmedia == "install" && $wimtools == "true" ]]; then
     if [[ $(wiminfo "$windisk"/sources/install.* 1 | grep -m 1 Name: | sed "s/^.*: *//") == "Windows 11"* ]]; then win11opts; fi
elif [[ $winmedia == "wintogo" && ! -z $(command -v hivexsh) ]]; then
     bcdpath="/Volumes/UFD-SYSTEM/EFI/Microsoft/Boot/BCD"
     if [[ -f "$bcdpath" ]]; then
        guidscript="cd Objects\\{9dea862c-5cdd-4e70-acc1-f32b344d4795}\\\Elements\\\23000003\nlsval Element\nunload\n"
        winguid=$(printf "$guidscript" | hivexsh "$bcdpath")
        namescript="cd Objects\\$winguid\\\Elements\\\12000004\nlsval Element\nunload\n"
        winprod=$(printf "$namescript" | hivexsh "$bcdpath")
        if [[ "$winprod" == "Windows 11" ]]; then win11opts; fi
     fi
else
    read -p "Is this a Windows 11 disk [Y/N]? " eleven
    eleven=${eleven^^}
    while [[ $eleven != "Y" && $eleven != "N" ]]; do
          echo -e "${RED}Invalid entry. Try again.${NC}"
          read -p "Is this a Windows 11 disk [Y/N]? " eleven
          eleven=${eleven^^}
    done
    if  [[ $eleven == "Y" ]]; then win11opts; fi
fi

localize="false"
read -p "Use the current language settings on this system [Y/N]? " uselocale
uselocale=${uselocale^^}
while [[ $uselocale != "Y" && $uselocale != "N" ]]; do
 echo -e "${RED}Invalid entry. Try again.${NC}"
 read -p "Use the current language settings on this system [Y/N]? " uselocale
 uselocale=${uselocale^^}
done
if  [[ $uselocale == "Y" ]]; then localize="true"; fi

settimezone="false"
if [[ ! -z $(command -v pwsh) ]]; then
   read -p "Use the current timezone setting on this system [Y/N]? " usetimezone
   usetimezone=${usetimezone^^}
   while [[ $usetimezone != "Y" && $usetimezone != "N" ]]; do
         echo -e "${RED}Invalid entry. Try again.${NC}"
         read -p "Use the current timezone setting on this system [Y/N]? " usetimezone
         usetimezone=${usetimezone^^}
   done
   if [[ $usetimezone == "Y" ]]; then settimezone="true"; fi
fi

useraccounts="false"
read -p "Create a local user account [Y/N]? " newuser
newuser=${newuser^^}
while [[ $newuser != "Y" && $newuser != "N" ]]; do
 echo -e "${RED}Invalid entry. Try again.${NC}"
 read -p "Create a local user account [Y/N]? " newuser
 newuser=${newuser^^}
done
if  [[ $newuser == "Y" ]]; then
    useraccounts="true"
    read -p "Enter a login name for new account [$USER]: " loginname
    if [[ $loginname == "" ]]; then
       loginname="$USER"
    fi
    if   [[ $system == "Darwin" ]]; then
         username=$(id -F)
    elif [[ $system == "Linux" ]]; then
         username=$(getent passwd $USER | awk -F: '{print $5}')
    fi
    read -p "Enter the full name for new account [$username]: " fullname
    if [[ $fullname == "" ]]; then
       fullname="$username"
    fi
    read -p "Enter a description for new account: " description
fi

skipwifisetup="false"
read -p "Skip the Join Wireless Network screen [Y/N]? " wifiscreen
wifiscreen=${wifiscreen^^}
while [[ $wifiscreen != "Y" && $wifiscreen != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Skip the Join Wireless Network screen [Y/N]? " wifiscreen
      wifiscreen=${wifiscreen^^}
done
if  [[ $wifiscreen == "Y" ]]; then skipwifisetup="true"; fi

disdatacol="false"
read -p "Disable data collection and privacy questions [Y/N]? " privacy
privacy=${privacy^^}
while [[ $privacy != "Y" && $privacy != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Disable data collection and privacy questions [Y/N]? " privacy
      privacy=${privacy^^}
done
if  [[ $privacy == "Y" ]]; then disdatacol="true"; fi

if  [[ $skipwifisetup == "true" || $disdatacol == "true" ]]; then oobe="true"; else oobe="false"; fi

disautoenc="false"
read -p "Disable BitLocker automatic drive encryption [Y/N]? " bitlocker
bitlocker=${bitlocker^^}
while [[ $bitlocker != "Y" && $bitlocker != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Disable BitLocker automatic drive encryption [Y/N]? " bitlocker
      bitlocker=${bitlocker^^}
done
if  [[ $bitlocker == "Y" ]]; then disautoenc="true"; fi

if   [[ $winmedia == "install" ]]; then
     if  [[ $unsupported == "false" && $localize == "false" ]]; then
         mkdir -p "$windisk/sources/\$OEM\$/\$\$/Panther"
         xmlpath="$windisk/sources/\$OEM\$/\$\$/Panther/unattend.xml"
     else
         xmlpath="$windisk/autounattend.xml"
     fi
elif [[ $winmedia == "wintogo" ]]; then
     mkdir "$windisk/Windows/Panther"
     xmlpath="$windisk/Windows/Panther/unattend.xml"
fi

(cd $resdir/Windows/Scripts; ./unattend.sh $unsupported $localize $bypassnro $oobe $settimezone $useraccounts $skipwifisetup $disdatacol $disautoenc "$loginname" "$fullname" "$description" > "$xmlpath")
}

win11opts () {
if [[ $winmedia == "install" ]]; then
   read -p "Disable TPM, Secure Boot and RAM requirements [Y/N]? " bypasshw
   bypasshw=${bypasshw^^}
   while [[ $bypasshw != "Y" && $bypasshw != "N" ]]; do
         echo -e "${RED}Invalid entry. Try again.${NC}"
         read -p "Disable TPM, Secure Boot and RAM requirements [Y/N]? " bypasshw
         bypasshw=${bypasshw^^}
   done
   if  [[ $bypasshw == "Y" ]]; then
       if  [[ $wimtools == "true" && ! -z $(command -v hivexregedit) ]]; then
           (cd $resdir/Windows/Scripts; ./unsupported.sh "$windisk")
       else
           unsupported="true"
       fi
   fi
fi
read -p "Disable requirement for an online Microsoft account [Y/N]? " msaccount
msaccount=${msaccount^^}
while [[ $msaccount != "Y" && $msaccount != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Disable requirement for an online Microsoft account [Y/N]? " msaccount
      msaccount=${msaccount^^}
done
if  [[ $msaccount == "Y" ]]; then bypassnro="true"; fi
}

show_about () {
clear
cat $resdir/Support/About.txt
echo
read -n 1 -s -r -p "Press any key to continue"
}

select_err () {
echo "Invalid selection try again."
sleep 1
}

# Script starts here.
RED='\033[1;31m'
NC='\033[0m' # No Color
system=`uname`

# Set resource location for supported platforms or exit.
if   [[ $system == "Darwin" ]]; then
     resdir="/opt/local/share/BOOTDISK"
elif [[ $system == "Linux" ]]; then
     resdir="/usr/local/share/BOOTDISK"
else
     echo "Unsupported platform detected."
     exit 1
fi

# Check for required packages that are missing.
if [[ -z $(command -v 7z) ]]; then missing+=" 7zip"; fi
if [[ -z $(command -v jq) ]]; then missing+=" jq"; fi
if [[ -z $(command -v curl) ]]; then missing+=" curl"; fi
if [[ $system == "Darwin" ]]; then
   bashver=$(bash --version | head -n 1 | awk '{print $4}' | cut -f1 -d'(')
   if  [ "$(printf '%s\n' "3.2.57" "$bashver" | sort -rV | head -n1)" == "3.2.57" ]; then
       missing+=" bash(>$bashver)"
   fi
fi
if [[ "$missing" != "" ]]; then
   echo "The following packages are required:""$missing"
   exit 1
fi

# Check for legacy BIOS and DOS support.
if   [[ ! -z $(command -v mtools) ]]; then
     mtools="true"
else
     mtools="false"
fi
if  [[ ! -z $(command -v ms-sys) ]]; then
    biosmode="true"
else
    biosmode="false"
fi

# Check if wimlib and its tools are installed.
if  [[ ! -z $(command -v wimlib-imagex) ]]; then
    wimtools="true"
else
    wimtools="false"
fi

# Download UEFI:NTFS bootloader if missing or outdated.
uefint_url="https://raw.githubusercontent.com/pbatard/rufus/master/res/uefi/uefi-ntfs.img"
uefint_commit_url="https://api.github.com/repos/pbatard/rufus/commits?path=res/uefi/uefi-ntfs.img&page=1&per_page=1"
uefint_commit_date=$(curl -s $uefint_commit_url | jq -r '.[0].commit.committer.date' | cut -f1 -d"T")
uefint_image_date=$($resdir/Support/modtime.py $resdir/Support/uefi-ntfs.img 2> /dev/null | awk '{print $1}')

if [[ ! -e $resdir/Support/uefi-ntfs.img ]] || [[ $uefint_commit_date > $uefint_image_date ]]; then
	rm -f $resdir/Support/uefi-ntfs.img 2> /dev/null
	curl -o $resdir/Support/uefi-ntfs.img $uefint_url 2> /dev/null
fi

# Display menu for installed options.
if   [[ "$mtools" == "true" && "$biosmode" == "true" ]]; then
     if [[ -e $resdir/MS-DOS/Files/COMMAND.COM ]]; then
	  menu_full
     else
	  menu_standard
     fi
else
	menu_default
fi
