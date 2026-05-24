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
.*******************************.
|         BOOTDISK v2.1         |
|                               |
|         _   ,--()             |
|        ( )-'-.------|>        |
|         "     \`--[]           |
|                               |
|  Flash Drive Formatting Tool  |
'*******************************'
Select an option:

EOF
}

lower_border () {
cat<<EOF
********************************
EOF
}

menu_full () {
while :
do
clear
if   [[ "$usezenity" == "true" ]]; then
     choice=$(zenity --list --cancel-label="Quit" --radiolist --width=400 --height=500 --title="BOOTDISK" --text="Select an option from the list:" --hide-header --hide-column=2 --print-column=2 --column="Select" --column="ID" --column="Boot Option" FALSE 1 "FreeDOS" FALSE 2 "MS-DOS" FALSE 3 "Windows" FALSE 4 "Linux/Other" FALSE 5 "Erase" FALSE 6 "Tools" FALSE 7 "About")
     if [[ $? -ne 0 ]]; then
          read <<< 8
     else
          read <<< $choice
     fi
else
title_block
cat<<EOF
FreeDOS 1.4  (1)
MS-DOS  8.0  (2)
Windows 7-11 (3)
Linux/Other  (4)
Erase Disk   (5)
Tools Menu   (6)
About        (7)
Quit         (8)
EOF
lower_border
read -p"Enter Choice: "
fi
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  msdosdisk   ;;
"3")  windowsmode ;;
"4")  linux_other ;;
"5")  erase_disk  ;;
"6")  menu_tools  ;;
"7")  show_about  ;;
"8")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_standard () {
while :
do
clear
if   [[ "$usezenity" == "true" ]]; then
     choice=$(zenity --list --cancel-label="Quit" --radiolist --width=400 --height=500 --title="BOOTDISK" --text="Select an option from the list:" --hide-header --hide-column=2 --print-column=2 --column="Select" --column="ID" --column="Boot Option" FALSE 1 "FreeDOS" FALSE 2 "Windows" FALSE 3 "Linux/Other" FALSE 4 "Erase" FALSE 5 "Tools" FALSE 6 "About")
     if [[ $? -ne 0 ]]; then
          read <<< 7
     else
          read <<< $choice
     fi
else
title_block
cat<<EOF
FreeDOS 1.4  (1)
Windows 7-11 (2)
Linux/Other  (3)
Erase Disk   (4)
Tools Menu   (5)
About        (6)
Quit         (7)
EOF
lower_border
read -p"Enter Choice: "
fi
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  windowsmode ;;
"3")  linux_other ;;
"4")  erase_disk  ;;
"5")  menu_tools  ;;
"6")  show_about  ;;
"7")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_default () {
while :
do
clear
if   [[ "$usezenity" == "true" ]]; then
     choice=$(zenity --list --cancel-label="Quit" --radiolist --width=400 --height=500 --title="BOOTDISK" --text="Select an option from the list:" --hide-header --hide-column=2 --print-column=2 --column="Select" --column="ID" --column="Boot Option" FALSE 1 "Windows" FALSE 2 "Linux/Other" FALSE 3 "Erase" FALSE 4 "Tools" FALSE 5 "About")
     if [[ $? -ne 0 ]]; then
          read <<< 6
     else
          read <<< $choice
     fi
else
title_block
cat<<EOF
Windows 7-11 (1)
Linux/Other  (2)
Erase Disk   (3)
Tools Menu   (4)
About        (5)
Quit         (6)
EOF
lower_border
read -p"Enter Choice: "
fi
case "$REPLY" in
"1")  windowsmode ;;
"2")  linux_other ;;
"3")  erase_disk  ;;
"4")  menu_tools  ;;
"5")  show_about  ;;
"6")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_tools () {
while :
do
clear
if   [[ "$usezenity" == "true" ]]; then
     choice=$(zenity --list --radiolist --width=350 --height=370 --title="BOOTDISK: Tools Menu" --text="Select an option from the list:" --hide-header --column="Select" --column="ID" --column="Tool Option" --hide-column=2 FALSE 1 "Extract MS-DOS" FALSE 2 "Download an ISO file" FALSE 3 "Windows ISO checksum" FALSE 4 "Windows Customization")
     if [[ $? -ne 0 ]]; then
          read <<< 5
     else
          read <<< $choice
     fi
else
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
fi
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

fdostitle() {
clear
echo "    FreeDOS 1.4 Boot Disk Script     "
echo "-------------------------------------"
}

fdosdisk () {
verbose="false"
if   [[ "$usezenity" == "true" ]]; then
     tgtdsk=$(eval zenity $zendevargs ${devices[@]})
     if [[ $? -ne 0 ]]; then return; fi
else
     while :
     do
           fdostitle
           echo -e "$dev_menu_top"; printf "%s" "${devices[@]}"; echo "$dev_menu_btm"
           read -p "Enter choice: " devnum
           if   [[ $devnum == [1-9] && $devnum -le ${#devices[@]} ]]; then
                tgtdsk=$(printf "%s" "${devices[(($devnum - 1))]}" | awk '{print $2}')
                break
           else
                select_err
           fi
     done
fi

if   [[ "$usezenity" == "true" ]]; then
     fmtopts=$(zenity --forms --title="BOOTDISK: FreeDOS" --text="Format Options" --add-combo="File System" --combo-values="FAT16|FAT32" --add-combo="Format Type" --combo-values="QUICK|FULL")
     if [[ $? -ne 0 ]]; then return; fi
     fstyp=$(echo $fmtopts | awk -F'|' '{print $1}')
     fmtyp=$(echo $fmtopts | awk -F'|' '{print $2}')
else
     fstyp=""
     while :
     do
           if [[ -z "$fstyp" ]]; then
              fdostitle
              echo -en "Block Device: /dev/$tgtdsk\n\n"
              echo -en "Format Options:\n\n(1) FAT16\n(2) FAT32\n\n"
              read -p "Enter choice: " fsnum
              case "$fsnum" in
                   "1")
                      fstyp="FAT16"
                      ;;
                   "2")
                      fstyp="FAT32"
                      ;;
                    * )
                      select_err
                      ;;
              esac
           fi
           if [[ ! -z "$fstyp" ]]; then
              fdostitle
              echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\n\n"
              echo -en "Format Options:\n\n(1) QUICK\n(2) FULL\n\n"
              read -p "Enter choice: " fmnum
              case "$fmnum" in
                   "1")
                      fmtyp="QUICK"
                      break
                      ;;
                   "2")
                      fmtyp="FULL"
                      break
                      ;;
                    * )
                      select_err
                      ;;
              esac
           fi
     done
fi

if   [[ "$usezenity" == "true" ]]; then
     if zenity --question --title="Verbose Format Option" \
        --text="Display detailed filesystem information?"; then
        verbose="true"
     fi
else
     fdostitle
     echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\nFormat Type:  $fmtyp\n\n"
     read -p "Display detailed filesystem information [Y/N]? " vfmtmode
     vfmtmode=${vfmtmode^^}
     while [[ $vfmtmode != "Y" && $vfmtmode != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Display detailed filesystem information [Y/N]? " vfmtmode
           vfmtmode=${vfmtmode^^}
     done
     if [[ $vfmtmode == "Y" ]]; then verbose="true"; fi
fi

if   [[ "$usezenity" == "true" ]]; then
     volname=$(zenity --entry --title="BOOTDISK: FreeDOS" --text="Volume Label:" --entry-text="FREEDOS")
     if [[ $? -ne 0 ]]; then return; fi
else
     fdostitle
     echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\nFormat Type:  $fmtyp\nVerbose Mode: ${verbose^^}\n\n"
     read -p "Enter label [FREEDOS]: " volname
     if [[ "$volname" == "" ]]; then volname=FREEDOS; fi
fi
volname=${volname^^}
n=${#volname}
while [ $n -gt 11 ]; do
      if   [[ "$usezenity" == "true" ]]; then
           zenity --warning --title="Volume Name" --text="Label must be eleven characters or less."
           volname=$(zenity --entry --title="BOOTDISK: FreeDOS" --text="Volume Label:" --entry-text="FREEDOS")
           if [[ $? -ne 0 ]]; then return; fi
      else
           echo -e "${RED}Label must be eleven characters or less.${NC}"
           read -p "Enter label [FREEDOS]: " volname
      fi
      if [[ "$volname" == "" ]]; then volname=FREEDOS; fi
      volname=${volname^^}
      n=${#volname}
done

if [[ "$usezenity" == "false" ]]; then
   fdostitle
   echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\nFormat Type:  $fmtyp\nVerbose Mode: ${verbose^^}\nVolume Label: $volname\n\n"
fi
(cd $resdir/FreeDOS; ./freedosdisk.sh $system $fstyp $fmtyp $verbose "$volname" $tgtdsk $usezenity)
}

msdos_title () {
clear
echo "     MS-DOS 8.0 Boot Disk Script     "
echo "-------------------------------------"
}
msdosdisk () {
verbose="false"
if   [[ "$usezenity" == "true" ]]; then
     tgtdsk=$(eval zenity $zendevargs ${devices[@]})
     if [[ $? -ne 0 ]]; then return; fi
else
     while :
     do
           msdos_title
           echo -e "$dev_menu_top"; printf "%s" "${devices[@]}"; echo "$dev_menu_btm"
           read -p "Enter choice: " devnum
           if   [[ $devnum == [1-9] && $devnum -le ${#devices[@]} ]]; then
                tgtdsk=$(printf "%s" "${devices[(($devnum - 1))]}" | awk '{print $2}')
                break
           else
                select_err
           fi
     done
fi

if   [[ "$usezenity" == "true" ]]; then
     fmtopts=$(zenity --forms --title="BOOTDISK: MS-DOS" --text="Format Options" --add-combo="File System" --combo-values="FAT16|FAT32" --add-combo="Format Type" --combo-values="QUICK|FULL")
     if [[ $? -ne 0 ]]; then return; fi
     fstyp=$(echo $fmtopts | awk -F'|' '{print $1}')
     fmtyp=$(echo $fmtopts | awk -F'|' '{print $2}')
else
     fstyp=""
     while :
     do
           if [[ -z "$fstyp" ]]; then
              msdos_title
              echo -en "Block Device: /dev/$tgtdsk\n\n"
              echo -en "Format Options:\n\n(1) FAT16\n(2) FAT32\n\n"
              read -p "Enter choice: " fsnum
              case "$fsnum" in
                   "1")
                      fstyp="FAT16"
                      ;;
                   "2")
                      fstyp="FAT32"
                      ;;
                    * )
                      select_err
                      ;;
              esac
           fi
           if [[ ! -z "$fstyp" ]]; then
              msdos_title
              echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\n\n"
              echo -en "Format Options:\n\n(1) QUICK\n(2) FULL\n\n"
              read -p "Enter choice: " fmnum
              case "$fmnum" in
                   "1")
                      fmtyp="QUICK"
                      break
                      ;;
                   "2")
                      fmtyp="FULL"
                      break
                      ;;
                    * )
                      select_err
                      ;;
              esac
           fi
     done
fi

if   [[ "$usezenity" == "true" ]]; then
     if zenity --question --title="Verbose Format Option" \
        --text="Display detailed filesystem information?"; then
        verbose="true"
     fi
else
     msdos_title
     echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\nFormat Type:  $fmtyp\n\n"
     read -p "Display detailed filesystem information [Y/N]? " vfmtmode
     vfmtmode=${vfmtmode^^}
     while [[ $vfmtmode != "Y" && $vfmtmode != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Display detailed filesystem information [Y/N]? " vfmtmode
           vfmtmode=${vfmtmode^^}
     done
     if [[ $vfmtmode == "Y" ]]; then verbose="true"; fi
fi

if   [[ "$usezenity" == "true" ]]; then
     volname=$(zenity --entry --title="BOOTDISK: MS-DOS" --text="Volume Label:" --entry-text="MSDOS80")
     if [[ $? -ne 0 ]]; then return; fi
else
     msdos_title
     echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\nFormat Type:  $fmtyp\nVerbose Mode: ${verbose^^}\n\n"
     read -p "Enter label [MSDOS80]: " volname
     if [[ "$volname" == "" ]]; then volname=MSDOS80; fi
fi
volname=${volname^^}
n=${#volname}
while [ $n -gt 11 ]; do
      if   [[ "$usezenity" == "true" ]]; then
           zenity --warning --title="Volume Name" --text="Label must be eleven characters or less."
           volname=$(zenity --entry --title="BOOTDISK: MS-DOS" --text="Volume Label:" --entry-text="MSDOS80")
           if [[ $? -ne 0 ]]; then return; fi
      else
           echo -e "${RED}Label must be eleven characters or less.${NC}"
           read -p "Enter label [MSDOS80]: " volname
      fi
      if [[ "$volname" == "" ]]; then volname=MSDOS80; fi
      volname=${volname^^}
      n=${#volname}
done

if [[ "$usezenity" == "false" ]]; then
   msdos_title
   echo -en "Block Device: /dev/$tgtdsk\nFile System:  $fstyp\nFormat Type:  $fmtyp\nVerbose Mode: ${verbose^^}\nVolume Label: $volname\n\n"
fi
(cd $resdir/MS-DOS; ./msdosdisk.sh $system $fstyp $fmtyp $verbose "$volname" $tgtdsk $usezenity)
}

windowsmode () {
wtgsupport="false"
if   [[ "$system" == "Darwin" ]]; then
     winfsopts="FAT32|EXFAT"
     if  [[ $personality == "Tuxera" || $personality == "UFSD_NTFS" ]]; then
         winfsopts+="|NTFS"
     fi
     if  [[ $personality == "Tuxera" || $personality == "UFSD_NTFS" ||
         ("$ntfs_make" == "true" && "$ntfs_progs" == "true") ]]; then
         if [[ $wimtools == "true" && ! -z $(command -v bcd-sys) ]]; then
            wtgsupport="true"
         fi
     fi
elif [[ "$system" == "Linux" ]]; then 
     winfsopts="FAT32"
     if [[ "$exfat_make" == "true" ]]; then winfsopts+="|EXFAT"; fi
     if [[ "$ntfs_make" == "true" ]]; then winfsopts+="|NTFS"; fi
     if [[ "$ntfs_make" == "true" && "$ntfs_progs" == "true" ]]; then
        if [[ $wimtools == "true" && ! -z $(command -v bcd-sys) ]]; then
           wtgsupport="true"
        fi
     fi
fi
if   [[ $wtgsupport == "true" ]]; then
     while :
     do
     clear
     if   [[ "$usezenity" == "true" ]]; then
          choice=$(zenity --list --radiolist --height=300 --width=100 --title="BOOTDISK" --text="Select an option from the list:" --hide-header --hide-column=2 --print-column=2 --column="Select" --column="ID" --column="Windows Option" FALSE 1 "Create install media" FALSE 2 "Create Windows To Go")
          if  [[ $? -ne 0 ]]; then
              read <<< 3
          else
              read <<< $choice
          fi
     else
          title_block
          echo "Create install media    (1)"
          echo "Create Windows to Go    (2)"
          echo "Return to Main Menu     (3)"
          lower_border
          read -p"Enter Choice: "
     fi
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

windisk_title () {
clear
echo "    Windows Install Disk Script    "
echo "-----------------------------------"
}

windowsdisk () {
image="N/A"
verbose="false"
uefiboot="false"
while true; do
      if   [[ "$usezenity" == "true" ]]; then
           image=$(zenity --file-selection --title="Select an ISO file" --file-filter="ISO Files|*.iso" 2> /dev/null)
           if [[ $? -ne 0 ]]; then return; fi
      else
           if [[ "$image" == "N/A" ]]; then windisk_title; fi
           read -p "Enter path to ISO file: " image
      fi
      if file "$image" | grep -q 'ISO 9660 CD-ROM filesystem data'; then isofile="true"; else isofile="false"; fi
      if [[ -f "$image" && "$isofile" == "true" ]]; then choices="Image file:   $(basename "$image")\n"; break; fi
      if   [[ "$usezenity" == "true" ]]; then
           zenity --error --title="Invalid Disk Image" --text="Selected file does not appear to be a valid ISO. Try again."
           if [[ $? -ne 0 ]]; then return; fi
      else
           echo -e "${RED}Invalid image file. Please try again.${NC}"
      fi
done

if   [[ "$usezenity" == "true" ]]; then
     tgtdsk=$(eval zenity $zendevargs ${devices[@]})
     if [[ $? -ne 0 ]]; then return; fi
else
     while :
     do
           windisk_title
           echo -en "$choices\n"
           echo -e "$dev_menu_top"; printf "%s" "${devices[@]}"; echo "$dev_menu_btm"
           read -p "Enter choice: " devnum
           if   [[ $devnum == [1-9] && $devnum -le ${#devices[@]} ]]; then
                tgtdsk=$(printf "%s" "${devices[(($devnum - 1))]}" | awk '{print $2}')
                break
           else
                select_err
           fi
     done
     choices+="Block Device: /dev/$tgtdsk\n"
fi

if   [[ "$usezenity" == "true" ]]; then
     layout=$(zenity --forms --title="BOOTDISK: Windows" --text="Disk Properties" --add-combo="Partition Scheme" --combo-values="MBR|GPT" --add-combo="File System" --combo-values="$winfsopts" --add-combo="Format Type" --combo-values="QUICK|FULL")
     if [[ $? -ne 0 ]]; then return; fi
     prtshm=$(echo $layout | awk -F'|' '{print $1}')
     fstyp=$(echo $layout | awk -F'|' '{print $2}')
     fmtyp=$(echo $layout | awk -F'|' '{print $3}')
else
     prtshm=""
     fstyp=""
     fmtyp=""
     ptarr=(GPT MBR)
     ptopts="(1) GPT\n(2) MBR"
     while :
     do
           if [[ -z "$prtshm" ]]; then
              windisk_title
              echo -en "$choices\n"
              echo -en "Format Options:\n\n$ptopts\n\n"
              read -p "Enter choice: " ptnum
              if   [[ $ptnum == [1-9] && $ptnum -le ${#ptarr[@]} ]]; then
                   prtshm=$(echo "${ptarr[(($ptnum - 1))]}")
                   fslist=$(echo $winfsopts | sed 's/|/\\n /g' | awk '{n=1} {for (i = 1; i<= NF; i++) printf("(%d) %s", n++, $i);}')
                   readarray -d'|' -t fsarr <<< $(echo $winfsopts)
                   choices+="Disk Layout:  $prtshm\n"
              else
                   select_err
              fi
           fi
           if [[ ! -z "$prtshm" && -z "$fstyp" ]]; then
              windisk_title
              echo -en "$choices\n"
              echo -en "Format Options:\n\n$fslist\n\n"
              read -p "Enter choice: " fsnum
              if   [[ $fsnum == [1-9] && $fsnum -le ${#fsarr[@]} ]]; then
                   fstyp=$(echo "${fsarr[(($fsnum - 1))]}")
                   choices+="File System:  $fstyp\n"
                   ftopts="(1) QUICK\n(2) FULL"
                   ftarr=(QUICK FULL)
              else
                   select_err
              fi
           fi
           if [[ ! -z "$prtshm" && ! -z "$fstyp" && -z "$fmtyp" ]]; then
              windisk_title
              echo -en "$choices\n"
              echo -en "Format Options:\n\n$ftopts\n\n"
              read -p "Enter choice: " ftnum
              if   [[ $ftnum == [1-9] && $ftnum -le ${#ftarr[@]} ]]; then
                   fmtyp=$(echo "${ftarr[(($ftnum - 1))]}")
                   choices+="Format Type:  $fmtyp\n"
                   break
              else
                   select_err
              fi
           fi
     done
fi

if   [[ "$usezenity" == "true" ]]; then
     if zenity --question --title="Verbose Format Option" \
        --text="Display detailed filesystem information?"; then
        verbose="true"
     fi
else
     windisk_title
     echo -en "$choices\n"
     read -p "Display detailed filesystem information [Y/N]? " vfmtmode
     vfmtmode=${vfmtmode^^}
     while [[ $vfmtmode != "Y" && $vfmtmode != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Display detailed filesystem information [Y/N]? " vfmtmode
           vfmtmode=${vfmtmode^^}
     done
     if [[ $vfmtmode == "Y" ]]; then verbose="true"; fi
     choices+="Verbose Mode: ${verbose^^}\n"
fi
    
if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]] && [[ -e $resdir/Support/uefi-ntfs.img ]]; then
   if   [[ "$usezenity" == "true" ]]; then
         if zenity --question --title="UEFI:NTFS" --text="Enable UEFI boot support?"; then uefint="Y"; else uefint="N"; fi
   else
        windisk_title
        echo -en "$choices\n"
        read -p "Enable UEFI boot support [Y/N]? " uefint
        uefint=${uefint^^}
        while [[ $uefint != "Y" && $uefint != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Enable UEFI boot support [Y/N]? " uefint
              uefint=${uefint^^}
        done
   fi
   if [[ "$uefint" == "Y" ]]; then uefiboot="true"; fi
   choices+="UEFI-NTFS:    ${uefiboot^^}\n"
fi

if   [[ "$usezenity" == "true" ]]; then
     volname=$(zenity --entry --title="BOOTDISK: Windows" --text="Volume Label:" --entry-text="WINDOWS")
     if [[ $? -ne 0 ]]; then return; fi
else
     windisk_title
     echo -en "$choices\n"
     read -p "Enter label [WINDOWS]: " volname
fi
n=${#volname}
if [[ $fstyp == "FAT32" || $fstyp == "EXFAT" ]]; then
   while [ $n -gt 11 ]; do
         if   [[ "$usezenity" == "true" ]]; then
              zenity --warning --title="Volume Name" --text="Label must be eleven characters or less."
              volname=$(zenity --entry --title="BOOTDISK: Windows" --text="Volume Label:" --entry-text="WINDOWS")
              if [[ $? -ne 0 ]]; then return; fi
         else
              echo -e "${RED}Label must be eleven characters or less.${NC}"
              read -p "Enter label [WINDOWS]: " volname
         fi
         n=${#volname}
   done
   if [[ $fstyp == "FAT32" ]]; then volname=${volname^^}; fi
elif [[ "$system" == "Linux" && $fstyp == "NTFS" ]]; then
     while [ $n -gt 128 ]; do
           if   [[ "$usezenity" == "true" ]]; then
                zenity --warning --title="Volume Name" --text="Label must be 128 characters or less."
                volname=$(zenity --entry --title="BOOTDISK: Windows" --text="Volume Label:" --entry-text="WINDOWS")
                if [[ $? -ne 0 ]]; then return; fi
           else
                echo -e "${RED}Label must be 128 characters or less.${NC}"
                read -p "Enter label [WINDOWS]: " volname
           fi
           n=${#volname}
     done
fi
if [[ "$volname" == "" ]]; then volname=WINDOWS; fi
if [[ "$usezenity" == "false" ]]; then choices+="Volume Label: $volname\n"; fi

if [[ "$usezenity" == "false" ]]; then windisk_title; echo -en "$choices\n"; fi
(cd $resdir/Windows; ./windowsdisk.sh $system $prtshm $fstyp $fmtyp $verbose $uefiboot "$volname" "$image" $wimtools $tgtdsk $usezenity)
}

wtgtitle () {
clear
echo "        Windows to Go Script        "
echo "------------------------------------"
}

windowstogo () {
image="N/A"
verbose="false"
fmtyp="QUICK"
if   [[ "$usezenity" == "true" ]]; then
     tgtdsk=$(eval zenity $zendevargs ${devices[@]})
     if [[ $? -ne 0 ]]; then return; fi
else
     while :
     do
           wtgtitle
           echo -e "$dev_menu_top"; printf "%s" "${devices[@]}"; echo "$dev_menu_btm"
           read -p "Enter choice: " devnum
           if   [[ $devnum == [1-9] && $devnum -le ${#devices[@]} ]]; then
                tgtdsk=$(printf "%s" "${devices[(($devnum - 1))]}" | awk '{print $2}')
                choices="Block Device: /dev/$tgtdsk\n"
                break
           else
                select_err
           fi
     done
fi

while true; do
      if   [[ "$usezenity" == "true" ]]; then
           image=$(zenity --file-selection --title="Select an ISO file" --file-filter="ISO Files|*.iso" 2> /dev/null)
           if [[ $? -ne 0 ]]; then return; fi
      else
           if [[ "$image" == "N/A" ]]; then wtgtitle; echo -en "$choices\n"; fi
           read -p "Enter path to ISO file: " image
      fi
      if file "$image" | grep -q 'ISO 9660 CD-ROM filesystem data'; then isofile="true"; else isofile="false"; fi
      if [[ -f "$image" && "$isofile" == "true" ]]; then break; fi
      if   [[ "$usezenity" == "true" ]]; then
           zenity --error --title="Invalid Disk Image" --text="Selected file does not appear to be a valid ISO. Try again."
           if [[ $? -ne 0 ]]; then return; fi
      else
           echo -e "${RED}Invalid image file. Please try again.${NC}"
      fi
done

if   [[ "$system" == "Darwin" ]]; then
     wimfile="/tmp/isomount/sources/install.wim"
     hdiutil attach "$image" -mountpoint /tmp/isomount -nobrowse > /dev/null
elif [[ "$system" == "Linux" ]]; then
     wimfile="/mnt/isomount/sources/install.wim"
     if [[ ! -f $wimfile ]]; then
        if   [[ "$usezenity" == "true" ]]; then
             if ! sudo -nv 2>/dev/null; then
                zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
	        if [[ $? -ne 0 ]]; then return; fi
	     fi
        else
             if ! sudo -nv 2>/dev/null; then
                echo "Mount install disk image (sudo required)..."
             fi
        fi
        sudo mkdir -p /mnt/isomount
        sudo mount -o ro,loop "$image" /mnt/isomount
     fi
fi
if [[ ! -f $wimfile ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        zenity --error --title="File Error" --text="Unable to find install archive in DVD image."
   else
        wtgtitle
        echo -en "$choices"
        echo -en "Image file:   $(basename "$image")\n\n"
        echo -e "${RED}Unable to find install archive in DVD image.${NC}"
        echo
        read -p "Press any key to continue... " -n1 -s
   fi
   return 1
fi

if   [[ "$usezenity" == "true" ]]; then
     if zenity --question --title="Enable Full Format Mode" \
        --text="Do you want to perform a full format?"; then
        fmtyp="FULL"
     fi
else
     wtgtitle
     echo -en "$choices\n"
     read -p "Do you want to perform a full format [Y/N]? " fullfmtmode
     fullfmtmode=${fullfmtmode^^}
     while [[ $fullfmtmode != "Y" && $fullfmtmode != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Do you want to perform a full format [Y/N]? " fullfmtmode
           fullfmtmode=${fullfmtmode^^}
     done
     if [[ $fullfmtmode == "Y" ]]; then fmtyp="FULL"; fi
     choices+="Format Mode:  ${fmtyp^^}\n"
fi

if   [[ "$usezenity" == "true" ]]; then
     if zenity --question --title="Verbose Format Option" \
        --text="Display detailed filesystem information?"; then
        verbose="true"
     fi
else
     wtgtitle
     echo -en "$choices\n"
     read -p "Display detailed filesystem information [Y/N]? " vfmtmode
     vfmtmode=${vfmtmode^^}
     while [[ $vfmtmode != "Y" && $vfmtmode != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Display detailed filesystem information [Y/N]? " vfmtmode
           vfmtmode=${vfmtmode^^}
     done
     if [[ $vfmtmode == "Y" ]]; then verbose="true"; fi
     choices+="Verbose Mode: ${verbose^^}\n"
fi

prodname=$(wiminfo $wimfile | grep -E '^(Name:)' | cut -d " " -f2- | sed 's/^[[:space:]]*//g')
if   [[ "$usezenity" == "true" ]]; then
     zenwtgargs='--list --radiolist --height=670 --title="BOOTDISK: Windows To Go" --text="Select which Windows version to install:" --hide-header --hide-column=2 --print-column=2 --column="Select" --column="ID" --column="Windows Version"'
     idxnum=$(wiminfo $wimfile | grep -E '^(Index:)' | cut -d " " -f2- | sed 's/^[[:space:]]*/FALSE /g')
     readarray -t versions <<< $(paste <(printf %s "$idxnum") <(printf %s "$prodname") | awk '{printf("%s %2s ", $1, $2); printf"\""; for (i = 3; i<= NF; i++) {printf "%s%s", $i, (i == NF ? "" : OFS);} printf "\"\n";}')
     index=$(eval zenity $zenwtgargs ${versions[@]})
     if [[ $? -ne 0 ]]; then index="q"; fi
else
     wtgtitle
     echo -en "$choices\n"
     idxnum=$(wiminfo $wimfile | grep -E '^(Index:)' | cut -d " " -f2- | sed 's/^[[:space:]]*//g;s/[0-9]$/&\./g')
     echo "Contents of $(basename "$image")"
     echo "$dev_menu_btm"
     paste <(printf %-3s "$idxnum") <(printf %s "$prodname") | column -s $'\t' -t
     echo "$dev_menu_btm"
     read -p "Enter Choice (q to Quit): " index
     while [[ $idxnum != *$index* && $index != "q" ]]; do
           echo -e "${RED}Invalid entry. Please try again.${NC}"
           read -p "Enter Choice: " index
     done
     choices+="Selection:    $(echo "$prodname" | awk "NR==$index")\n"
fi

if [[ "$index" != "q" ]]; then
   wtgtitle
   echo -en "$choices\n"
   (cd $resdir/Windows; ./windowstogo.sh $system $wimfile $fmtyp $verbose $index $tgtdsk $usezenity)
fi

if [[ $? -ne 0 ]]; then wtgerror="true"; else wtgerror="false"; fi
rm -f /tmp/wimfile_errors.txt
if [[ "$usezenity" == "false" ]]; then
   echo "Unmount install disk image..."
fi
if   [[ "$system" == "Darwin" ]]; then
     hdiutil detach /tmp/isomount > /dev/null
elif [[ "$system" == "Linux" ]]; then
     sudo umount /mnt/isomount && sudo rm -d /mnt/isomount
fi
if [[ "$usezenity" == "false" ]]; then
   if  [[ $wtgerror == "true" ]]; then
       echo
       read -p "Press any key to continue... " -n1 -s
       return 1
   else
       echo "Finished!"
       sleep 2
   fi
fi
}

linux_other_title () {
clear
echo "       Linux and Other Script        "
echo "-------------------------------------"
}

linux_other () {
wipedisk="false"
ddmode="false"
datapart="false"
verbose="false"
prtshm="CURRENT"
pstpart="N/A"
fstyp="N/A"
fmtyp="N/A"
fspst="N/A"
fmpst="N/A"
image="N/A"
volname="N/A"
fmtopts="FAT16|FAT32"
ubtdistrolist="elementary|Ubuntu|Mint|Pop_OS|Zorin|neon"
pstcompatlist="$ubtdistrolist|d-live|Fedora|CDROM|gentoo"
while true; do
      if   [[ "$usezenity" == "true" ]]; then
           image=$(zenity --file-selection --title="Select a disk image" --file-filter="ISO Files|*.iso" --file-filter="All files | *" 2> /dev/null)
           if [[ $? -ne 0 ]]; then return; fi
      else
           if [[ "$image" == "N/A" ]]; then linux_other_title; fi
           read -p "Enter path to file: " image
      fi
      while [[ ! -f "$image" ]]; do
            if   [[ "$usezenity" == "true" ]]; then
                 zenity --error --title="File Error" --text="Unable to access image file. Try again."
                 image=$(zenity --file-selection --title="Select a disk image" --file-filter="ISO Files|*.iso" --file-filter="All files | *" 2> /dev/null)
                 if [[ $? -ne 0 ]]; then return; fi
            else
                 echo -e "${RED}Unable to access image file. Try again.${NC}"
                 read -p "Enter path to file: " image
            fi
      done
      if file "$image" | grep -q 'ISO 9660 CD-ROM filesystem data'; then isofile="true"; else isofile="false"; fi
      choices="Image file:   $(basename "$image")\n"
      if   [[ "$system" == "Darwin" ]]; then
           isodevinfo=$(hdiutil attach -nomount "$image" 2> /dev/null | head -n1)
           isoblkdev=$(echo "$isodevinfo" | awk '{print $1}')
           prtable=$(echo "$isodevinfo" | awk '{print $2}')
           hdiutil detach $isoblkdev &> /dev/null
      elif [[ "$system" == "Linux" ]]; then
           prtable=$(fdisk -l "$image" 2> /dev/null | grep 'Disklabel type:')
      fi
      if [[ "$isofile" == "true" || ! -z "$prtable" ]]; then break; fi
      if   [[ "$usezenity" == "true" ]]; then
           zenity --error --title="Invalid Disk Image" --text="Image file does not have a partition table. Try again."
           if [[ $? -ne 0 ]]; then return; fi
      else
           echo -e "${RED}Image file does not have a partition table. Try again.${NC}"
      fi
done
if   [[ "$isofile" == "true" ]]; then
     if [[ ! -z "$prtable" ]]; then hybridiso="true"; else hybridiso="false"; fi
     if [[ "$hybridiso" == "true" ]]; then
        if   [[ "$usezenity" == "true" ]]; then
             if zenity --question --title="Direct Write" --text="Write image using the dd utility?"; then ddwrite="Y"; else ddwrite="N"; fi
        else
             linux_other_title
             echo -en "$choices\n"
             read -p "Write image using the dd utility [Y/N]? " ddwrite
             ddwrite=${ddwrite^^}
             while [[ $ddwrite != "Y" && $ddwrite != "N" ]]; do
                   echo -e "${RED}Invalid entry. Try again.${NC}"
                   read -p "Write image using the dd utility [Y/N]? " ddwrite
                   ddwrite=${ddwrite^^}
             done
        fi
        if [[ "$ddwrite" == "Y" ]]; then prtshm="ERASE"; ddmode="true"; fi
        choices+="Direct Write: ${ddmode^^}\n"
     fi
     if [[ "$hybridiso" == "false" || "$ddmode" == "false" ]]; then
        if   [[ "$usezenity" == "true" ]]; then
             if zenity --question --title="Erase Disk" --text="Wipe disk before extracting files?"; then wipe="Y"; else wipe="N"; fi
        else
             linux_other_title
             echo -en "$choices\n"
             read -p "Wipe disk before extracting files [Y/N]? " wipe
             wipe=${wipe^^}
             while [[ $wipe != "Y" && $wipe != "N" ]]; do
                   echo -e "${RED}Invalid entry. Try again.${NC}"
                   read -p "Wipe disk before extracting files [Y/N]? " wipe
                   wipe=${wipe^^}
             done
        fi
        if [[ $wipe == "Y" ]]; then wipedisk="true"; fi
        choices+="Erase Disk:   ${wipedisk^^}\n"
     fi
else
     prtshm="ERASE"
fi

if  [[ "$wipedisk" == "true" || "$prtshm" == "ERASE" ]]; then
    if   [[ "$usezenity" == "true" ]]; then
         target=$(eval zenity $zendevargs ${devices[@]})
         if [[ $? -ne 0 ]]; then return; fi
    else
         while :
         do
               linux_other_title
               echo -en "$choices\n"
               echo -e "$dev_menu_top"; printf "%s" "${devices[@]}"; echo "$dev_menu_btm"
               read -p "Enter choice: " devnum
               if   [[ $devnum == [1-9] && $devnum -le ${#devices[@]} ]]; then
                    target=$(printf "%s" "${devices[(($devnum - 1))]}" | awk '{print $2}')
                    choices+="Block Device: /dev/$target\n"
                    break
               else
                    select_err
               fi
         done
    fi
    if [[ "$wipedisk" == "true" ]]; then
       if file "$image" | grep -qiE "MX-Live"; then
          if   [[ "$system" == "Darwin" ]]; then
               fmtopts+="|EXFAT"
          elif [[ "$system" == "Linux" ]]; then
               fmtopts+="|EXT2|EXT3|EXT4"
          fi
       fi
       if file "$image" | grep -qiE "$pstcompatlist"; then
          if   [[ ! -z $(command -v mke2fs) ]]; then
               if   [[ "$usezenity" == "true" ]]; then
                    pstmaxsz=$(Support/linuxotherdisk.sh $system "$image" "$target" "NONE" getmaxsize false)
                    pstpartsz=$(zenity --scale --title="BOOTDISK: Linux/Other" --text="Select size of persistent partition (MiB)." \
                    --value=0 --min-value=0 --max-value=$pstmaxsz --step=1024)
                    if [[ $? -ne 0 ]]; then return; fi
                    if   [ $pstpartsz -eq $pstmaxsz ]; then
                         pstpartsz="MAX"
                    else
                         pstpartsz=$pstpartsz'M'
                    fi
               else
                    linux_other_title
                    echo -en "$choices\n"
                    read -p "Enter size of persistent partition [0M]: " pstpartsz
               fi
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
                          choices+="Persistence:  $pstpart\n"
                          if   [[ "$usezenity" == "true" ]]; then
                               if zenity --question --title="Data Partition" --text="Would you like to create a data partition?"; \
                               then mkdataprt="Y"; else mkdataprt="N"; fi
                          else
                               linux_other_title
                               echo -en "$choices\n"
                               read -p "Would you like to create a data partition [Y/N]? " mkdataprt
                               mkdataprt=${mkdataprt^^}
                               while [[ $mkdataprt != "Y" && $mkdataprt != "N" ]]; do
                                     echo -e "${RED}Invalid entry. Try again.${NC}"
                                     read -p "Would you like to create a data partition [Y/N]? " mkdataprt
                                     mkdataprt=${mkdataprt^^}
                               done
                          fi
                          if [[ $mkdataprt == "Y" ]]; then datapart="true"; fi
                          choices+="Data Volume:  ${datapart^^}\n"
                       fi
                  fi
               fi
          elif file "$image" | grep -qiE "$ubtdistrolist"; then
               if   [[ "$usezenity" == "true" ]]; then
                    if zenity --question --title="Persistence Partition" \
                    --text="Allow linux to use the remaining space for persistence?"; \
                    then enablepst="Y"; else enablepst="N"; fi
               else
                    linux_other_title
                    echo -en "$choices\n"
                    read -p "Allow linux to use the remaining space for persistence [Y/N]? " enablepst
                    enablepst=${enablepst^^}
                    while [[ $enablepst != "Y" && $enablepst != "N" ]]; do
                          echo -e "${RED}Invalid entry. Try again.${NC}"
                          read -p "Allow linux to use the remaining space for persistence [Y/N]?  " enablepst
                          enablepst=${enablepst^^}
                    done
               fi
               if [[ $enablepst == "Y" ]]; then pstpart="deferred"; fi
               choices+="Persistence:  $pstpart\n"
          fi
       fi
       if   [[ "$usezenity" == "true" ]]; then
            layout=$(zenity --forms --title="BOOTDISK: Linux/Other" --text="Disk Properties" --add-combo="Partition Scheme" --combo-values="MBR|GPT" --add-combo="File System" --combo-values="$fmtopts")
            if [[ $? -ne 0 ]]; then return; fi
            prtshm=$(echo $layout | awk -F'|' '{print $1}')
            fstyp=$(echo $layout | awk -F'|' '{print $2}')
            if [[ $fstyp == "EXT"* ]]; then ftopts="QUICK|FULL-READ|FULL-WRITE"; else ftopts="QUICK|FULL"; fi
            layout=$(zenity --forms --title="BOOTDISK: Linux/Other" --text="Disk Properties" --add-combo="Partition Scheme" --combo-values="$prtshm" --add-combo="File System" --combo-values="$fstyp" --add-combo="Format Type" --combo-values="$ftopts")
            if [[ $? -ne 0 ]]; then return; fi
            fmtyp=$(echo $layout | awk -F'|' '{print $3}')
            if [[ "$pstpart" != "N/A" ]]; then
               if   [[ "$fstyp" != "EXT"* ]]; then
                    layout=$(zenity --forms --title="BOOTDISK: Linux/Other" --text="Persistent Partition" --add-combo="File System" --combo-values="EXT2|EXT3|EXT4" --add-combo="Format Type" --combo-values="QUICK|FULL-READ|FULL-WRITE")
                    fspst=$(echo $layout | awk -F'|' '{print $1}')
                    fmpst=$(echo $layout | awk -F'|' '{print $2}')
               else
                    fspst="$fstyp"
                    fmpst="$fmtyp"
               fi
            fi
       else
            prtshm=""
            fstyp=""
            fmtyp=""
            if [[ "$pstpart" != "N/A" ]]; then
               fspst=""
               fmpst=""
            fi
            ptarr=(GPT MBR)
            ptopts="(1) GPT\n(2) MBR"
            while :
            do
                  if [[ -z "$prtshm" ]]; then
                     linux_other_title
                     echo -en "$choices\n"
                     echo -en "Format Options:\n\n$ptopts\n\n"
                     read -p "Enter choice: " ptnum
                     if   [[ $ptnum == [1-9] && $ptnum -le ${#ptarr[@]} ]]; then
                          prtshm=$(echo "${ptarr[(($ptnum - 1))]}")
                          fslist=$(echo $fmtopts | sed 's/|/\\n /g' | awk '{n=1} {for (i = 1; i<= NF; i++) printf("(%d) %s", n++, $i);}')
                          readarray -d'|' -t fsarr <<< $(echo $fmtopts)
                          choices+="Disk Layout:  $prtshm\n"
                     else
                          select_err
                     fi
                  fi
                  if [[ ! -z "$prtshm" && -z "$fstyp" ]]; then
                     linux_other_title
                     echo -en "$choices\n"
                     echo -en "Format Options:\n\n$fslist\n\n"
                     read -p "Enter choice: " fsnum
                     if   [[ $fsnum == [1-9] && $fsnum -le ${#fsarr[@]} ]]; then
                          fstyp=$(echo "${fsarr[(($fsnum - 1))]}")
                          choices+="File System:  $fstyp\n"
                          if   [[ $fstyp == "EXT"* ]]; then
                               ftopts="(1) QUICK\n(2) FULL-READ\n(3) FULL-WRITE"
                               ftarr=(QUICK FULL-READ FULL-WRITE)
                          else
                               ftopts="(1) QUICK\n(2) FULL"
                               ftarr=(QUICK FULL)
                          fi
                     else
                          select_err
                     fi
                  fi
                  if [[ ! -z "$prtshm" && ! -z "$fstyp" && -z "$fmtyp" ]]; then
                     linux_other_title
                     echo -en "$choices\n"
                     echo -en "Format Options:\n\n$ftopts\n\n"
                     read -p "Enter choice: " ftnum
                     if   [[ $ftnum == [1-9] && $ftnum -le ${#ftarr[@]} ]]; then
                          fmtyp=$(echo "${ftarr[(($ftnum - 1))]}")
                          choices+="Format Type:  $fmtyp\n"
                          if [[ "$pstpart" == "N/A" ]]; then break; fi
                     else
                          select_err
                     fi
                   fi
                   if [[ "$pstpart" != "N/A" && "$pstpart" != "deferred" ]]; then
                      if   [[ "$fstyp" != "EXT"* ]]; then
                           fspstarr=(EXT2 EXT3 EXT4)
                           fmpstarr=(QUICK FULL-READ FULL-WRITE)
                           if [[ -z "$fspst" ]]; then
                              linux_other_title
                              echo -en "$choices\n"
                              echo -en "Persistence Options:\n\nFile System\n\n(1) EXT2\n(2) EXT3\n(3) EXT4\n\n"
                              read -p "Enter choice: " fspstnum
                              if   [[ $fspstnum == [1-9] && $fspstnum -le ${#fspstarr[@]} ]]; then
                                   fspst=$(echo "${fspstarr[(($fspstnum - 1))]}")
                                   choices+="Persistence:  $fspst\n"
                              else
                                   select_err
                              fi
                           fi
                           if [[ ! -z "$fspst"  && -z "$fmpst" ]]; then
                              linux_other_title
                              echo -en "$choices\n"
                              echo -en "Persistence Options:\n\nFormat Type\n\n(1) QUICK\n(2) FULL-READ\n(3) FULL-WRITE\n\n"
                              read -p "Enter choice: " fmpstnum
                              if   [[ $fmpstnum == [1-9] && $fmpstnum -le ${#fmpstarr[@]} ]]; then
                                   fmpst=$(echo "${fmpstarr[(($fmpstnum - 1))]}")
                                   choices+="Persistence:  $fmpst\n"
                                   break
                              else
                                   select_err
                              fi
                           fi
                      else
                           fspst="$fstyp"
                           fmpst="$fmtyp"
                      fi
                   fi
            done
       fi
       if   [[ "$usezenity" == "true" ]]; then
            if zenity --question --title="Verbose Format Option" \
               --text="Display detailed filesystem information?"; then
               verbose="true"
            fi
       else
            linux_other_title
            echo -en "$choices\n"
            read -p "Display detailed filesystem information [Y/N]? " vfmtmode
            vfmtmode=${vfmtmode^^}
            while [[ $vfmtmode != "Y" && $vfmtmode != "N" ]]; do
                  echo -e "${RED}Invalid entry. Try again.${NC}"
                  read -p "Display detailed filesystem information [Y/N]? " vfmtmode
                  vfmtmode=${vfmtmode^^}
            done
            if [[ $vfmtmode == "Y" ]]; then verbose="true"; fi
            choices+="Verbose Mode: ${verbose^^}\n"
       fi
       shopt -s extglob
       volname=$(file "$image" | awk -F"'" '{for (i=2; i<=NF; i+=2) print $i}' | head -c 11)
       volname=${volname//[\*\?\/\\\|\,\;\:\+\=\<\>\[\]\"\.]/}
       volname=${volname##*( )}
       volname=${volname%%*( )}
       volname=${volname^^}
       if   [[ "$usezenity" == "true" ]]; then
            newvolname=$(zenity --entry --title="BOOTDISK: Linux/Other" --text="Volume Label:" --entry-text="$volname")
            if [[ $? -ne 0 ]]; then return; fi
       else
            linux_other_title
            echo -en "$choices\n"
            read -p "Enter label [$volname]: " newvolname
       fi
       if [[ ! -z "$newvolname" && "$newvolname" != "$volname" ]]; then
          n=${#newvolname}
          while [ $n -gt 11 ]; do
                if   [[ "$usezenity" == "true" ]]; then
                     zenity --warning --title="Volume Name" --text="Label must be eleven characters or less."
                     volname=$(zenity --entry --title="BOOTDISK: Linux/Other" --text="Volume Label:" --entry-text="$volname")
                     if [[ $? -ne 0 ]]; then return; fi
                else
                     echo -e "${RED}Label must be eleven characters or less.${NC}"
                     read -p "Enter label [$volname]: " newvolname
                fi
                n=${#newvolname}
          done
          volname="$newvolname"
          volname=${volname^^}
       fi
       if [[ "$usezenity" == "false" ]]; then
          choices+="Volume Label: $volname\n"
       fi
    fi
else
    if   [[ "$system" == "Darwin" ]]; then
         expath="/Volumes/Untitled"
    elif [[ "$system" == "Linux" ]]; then
         expath="/media/user/USBDISK"
    fi
    if   [[ "$usezenity" == "true" ]]; then
         target=$(zenity --file-selection --directory --title="Select the destination drive" 2> /dev/null)
         if [[ $? -ne 0 ]]; then return; fi
    else
         linux_other_title
         echo -en "$choices\n"
         read -p "Enter path to disk [$expath]: " target
         choices+="Target Volume: $target\n"
    fi
fi

if [[ "$usezenity" == "false" ]]; then linux_other_title; echo -en "$choices\n"; fi
(cd $resdir/Support; ./linuxotherdisk.sh $system "$image" "$target" $prtshm $pstpart $datapart $fstyp $fmtyp $fspst $fmpst $verbose "$volname" $usezenity)
}

erase_title () {
clear
echo "      Disk Erase/Wipe Script      "
echo "----------------------------------"
}

erase_disk () {
uefiboot="false"
setowner="false"
verbose="false"
have_apfs="false"
udfinfo="false"
fsopts="FAT16|FAT32"
udfdata=("empty" "empty" "empty")

if   [[ "$system" == "Darwin" ]]; then
     fsopts+="|EXFAT"
     if [[ $personality == "Tuxera" || $personality == "UFSD_NTFS" ]]; then
        fsopts+="|NTFS"
     fi
     fsopts+="|UDF|JHFS+"
     if [[ ! -z $(command -v newfs_apfs) ]]; then have_apfs="true"; fi
elif [[ "$system" == "Linux" ]]; then
     fsopts+="|EXT2|EXT3|EXT4"
     if [[ "$exfat_make" == "true" ]]; then fsopts+="|EXFAT"; fi
     if [[ "$ntfs_make" == "true" ]]; then fsopts+="|NTFS"; fi
     if [[ "$udf_make" == "true" ]]; then fsopts+="|UDF"; fi
fi

if   [[ "$usezenity" == "true" ]]; then
     tgtdsk=$(eval zenity $zendevargs ${devices[@]})
     if [[ $? -ne 0 ]]; then return; fi
else
     while :
     do
           erase_title
           echo -e "$dev_menu_top"; printf "%s" "${devices[@]}"; echo "$dev_menu_btm"
           read -p "Enter choice: " devnum
           if   [[ $devnum == [1-9] && $devnum -le ${#devices[@]} ]]; then
                tgtdsk=$(printf "%s" "${devices[(($devnum - 1))]}" | awk '{print $2}')
                break
           else
                select_err
           fi
     done
fi

if   [[ "$usezenity" == "true" ]]; then
     layout=$(zenity --forms --title="BOOTDISK: Erase/Wipe" --text="Disk Properties" --add-combo="Partition Scheme" --combo-values="MBR|GPT|SFD" --add-combo="File System" --combo-values="$fsopts")
     if [[ $? -ne 0 ]]; then return; fi
     prtshm=$(echo $layout | awk -F'|' '{print $1}')
     fstyp=$(echo $layout | awk -F'|' '{print $2}')
     if [[ $fstyp == "EXT"* ]]; then ftopts="QUICK|FULL-READ|FULL-WRITE"; else ftopts="QUICK|FULL"; fi
     layout=$(zenity --forms --title="BOOTDISK: Erase/Wipe" --text="Disk Properties" --add-combo="Partition Scheme" --combo-values="$prtshm" --add-combo="File System" --combo-values="$fstyp" --add-combo="Format Type" --combo-values="$ftopts")
     if [[ $? -ne 0 ]]; then return; fi
     fmtyp=$(echo $layout | awk -F'|' '{print $3}')
else
     prtshm=""
     fstyp=""
     fmtyp=""
     ptarr=(GPT MBR SFD)
     ptopts="(1) GPT\n(2) MBR\n(3) SFD"
     choices="Block Device: /dev/$tgtdsk\n"
     while :
     do
           if [[ -z "$prtshm" ]]; then
              erase_title
              echo -en "$choices\n"
              echo -en "Format Options:\n\n$ptopts\n\n"
              read -p "Enter choice: " ptnum
              if   [[ $ptnum == [1-9] && $ptnum -le ${#ptarr[@]} ]]; then
                   prtshm=$(echo "${ptarr[(($ptnum - 1))]}")
                   if [[ "$have_apfs" == "true" && $prtshm == "GPT" ]]; then fsopts+="|APFS"; fi
                   fslist=$(echo $fsopts | sed 's/|/\\n /g' | awk '{n=1} {for (i = 1; i<= NF; i++) printf("(%d) %s", n++, $i);}')
                   readarray -d'|' -t fsarr <<< $(echo $fsopts)
                   choices+="Disk Layout:  $prtshm\n"
              else
                   select_err
              fi
           fi
           if [[ ! -z "$prtshm" && -z "$fstyp" ]]; then
              erase_title
              echo -en "$choices\n"
              echo -en "Format Options:\n\n$fslist\n\n"
              read -p "Enter choice: " fsnum
              if   [[ $fsnum == [1-9] && $fsnum -le ${#fsarr[@]} ]]; then
                   fstyp=$(echo "${fsarr[(($fsnum - 1))]}")
                   choices+="File System:  $fstyp\n"
                   if   [[ $fstyp == "EXT"* ]]; then
                        ftopts="(1) QUICK\n(2) FULL-READ\n(3) FULL-WRITE"
                        ftarr=(QUICK FULL-READ FULL-WRITE)
                   else
                        ftopts="(1) QUICK\n(2) FULL"
                        ftarr=(QUICK FULL)
                   fi
              else
                   select_err
              fi
           fi
           if [[ ! -z "$prtshm" && ! -z "$fstyp" && -z "$fmtyp" ]]; then
              erase_title
              echo -en "$choices\n"
              echo -en "Format Options:\n\n$ftopts\n\n"
              read -p "Enter choice: " ftnum
              if   [[ $ftnum == [1-9] && $ftnum -le ${#ftarr[@]} ]]; then
                   fmtyp=$(echo "${ftarr[(($ftnum - 1))]}")
                   choices+="Format Type:  $fmtyp\n"
                   break
              else
                   select_err
              fi
           fi
     done
fi

if [[ $fstyp != "APFS" ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        if zenity --question --title="Verbose Format Option" \
           --text="Display detailed filesystem information?"; then
           verbose="true"
        fi
   else
        erase_title
        echo -en "$choices\n"
        read -p "Display detailed filesystem information [Y/N]? " vfmtmode
        vfmtmode=${vfmtmode^^}
        while [[ $vfmtmode != "Y" && $vfmtmode != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Display detailed filesystem information [Y/N]? " vfmtmode
              vfmtmode=${vfmtmode^^}
        done
        if [[ $vfmtmode == "Y" ]]; then verbose="true"; fi
        choices+="Verbose Mode: ${verbose^^}\n"
   fi
fi

if [[ $fstyp == "EXT"* || $fstyp == "JHFS+" || $fstyp == "APFS" ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        if zenity --question --title="Root Directory Ownership" \
        --text="Do you want \"$username\" to be owner of this volume?"; then
        setowner="true"; fi
   else
        erase_title
        echo -en "$choices\n"
        read -p "Do you want \"$username\" to be owner of this volume [Y/N]? " getowner
        getowner=${getowner^^}
        while [[ $getowner != "Y" && $getowner != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Do you want \"$username\" to be owner of this volume [Y/N]? " getowner
              getowner=${getowner^^}
        done
        if [[ $getowner == "Y" ]]; then setowner="true"; fi
        choices+="Volume Owner: ${setowner^^}\n"
   fi
fi

if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]] && [[ $prtshm != "SFD" && -e $resdir/Support/uefi-ntfs.img ]]; then
   if   [[ "$usezenity" == "true" ]]; then
         if zenity --question --title="UEFI:NTFS" --text="Enable UEFI boot support?"; then uefint="Y"; else uefint="N"; fi
   else
        erase_title
        echo -en "$choices\n"
        read -p "Enable UEFI boot support [Y/N]? " uefint
        uefint=${uefint^^}
        while [[ $uefint != "Y" && $uefint != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Enable UEFI boot support [Y/N]? " uefint
              uefint=${uefint^^}
        done
   fi
   if [[ "$uefint" == "Y" ]]; then uefiboot="true"; fi
   choices+="UEFI-NTFS:    ${uefiboot^^}\n"
fi

if [[ $fstyp == "UDF" && "$system" == "Linux" ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        if zenity --question --title="UDF Volume Descriptor" \
        --text="Set owner, organization and contact information?"; then setudfinfo="Y"; else setudfinfo="N"; fi
   else
        erase_title
        echo -en "$choices\n"
        read -p "Set owner, organization and contact information [Y/N]? " setudfinfo
        setudfinfo=${setudfinfo^^}
        while [[ $setudfinfo != "Y" && $setudfinfo != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Set owner, organization and contact information [Y/N]? " setudfinfo
              setudfinfo=${setudfinfo^^}
        done
   fi
   if [[ "$setudfinfo" == "Y" ]]; then
      if   [[ "$usezenity" == "true" ]]; then
           udfowner=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Volume Owner:" --entry-text="$username")
           if [[ $? -ne 0 || -z "$udfowner" ]]; then udfowner="empty"; fi
           udforg=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Organization Name:")
           if [[ $? -ne 0 || -z "$udforg" ]]; then udforg="empty"; fi
           udfcontact=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Contact Information:")
           if [[ $? -ne 0 || -z "$udfcontact" ]]; then udfcontact="empty"; fi
      else
           erase_title
           echo -en "$choices\n"
           read -p "Volume Owner [$username]: " udfowner
           if [[ -z "$udfowner" ]]; then udfowner="$username"; fi
           read -p "Organization Name: " udforg
           if [[ -z "$udforg" ]]; then udforg="empty"; fi
           read -p "Contact Information: " udfcontact
           if [[ -z "$udfcontact" ]]; then udfcontact="empty"; fi
      fi
      if [[ "${udfowner,,}" != "empty" ]]; then udfdata[0]="$udfowner"; fi
      if [[ "${udforg,,}" != "empty" ]]; then udfdata[1]="$udforg"; fi
      if [[ "${udfcontact,,}" != "empty" ]]; then udfdata[2]="$udfcontact"; fi
      udfinfo="true"
   fi
   choices+="Volume Info:  ${udfinfo^^}\n"
fi

if   [[ "$usezenity" == "true" ]]; then
     volname=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Volume Label:" --entry-text="STORAGE")
     if [[ $? -ne 0 ]]; then return; fi
else
     erase_title
     echo -en "$choices\n"
     read -p "Enter label [STORAGE]: " volname
fi
n=${#volname}
if [[ $fstyp == "FAT"* || $fstyp == "EXFAT" ]]; then
   while [ $n -gt 11 ]; do
         if   [[ "$usezenity" == "true" ]]; then
              zenity --warning --title="Volume Name" --text="Label must be eleven characters or less."
              volname=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Volume Label:" --entry-text="STORAGE")
              if [[ $? -ne 0 ]]; then return; fi
         else
              echo -e "${RED}Label must be eleven characters or less.${NC}"
              read -p "Enter label [STORAGE]: " volname
         fi
         n=${#volname}
   done
   if [[ $fstyp == "FAT"* ]]; then volname=${volname^^}; fi
elif [[ "$system" == "Linux" && ($fstyp == "NTFS" || $fstyp == "UDF") ]] || [[ "$system" == "Darwin" && $fstyp == "UDF" ]]; then
     while [ $n -gt 128 ]; do
           if   [[ "$usezenity" == "true" ]]; then
                zenity --warning --title="Volume Name" --text="Label must be 128 characters or less."
                volname=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Volume Label:" --entry-text="STORAGE")
                if [[ $? -ne 0 ]]; then return; fi
           else
                echo -e "${RED}Label must be 128 characters or less.${NC}"
                read -p "Enter label [STORAGE]: " volname
           fi
           n=${#volname}
     done
elif [[ $fstyp == "EXT"* ]]; then
     while [ $n -gt 16 ]; do
           if   [[ "$usezenity" == "true" ]]; then
                zenity --warning --title="Volume Name" --text="Label must be sixteen characters or less."
                volname=$(zenity --entry --title="BOOTDISK: Erase/Wipe" --text="Volume Label:" --entry-text="STORAGE")
                if [[ $? -ne 0 ]]; then return; fi
           else
                echo -e "${RED}Label must be sixteen characters or less.${NC}"
                read -p "Enter label [STORAGE]: " volname
           fi
           n=${#volname}
     done
fi
if [[ -z "$volname" ]]; then volname=STORAGE; fi

if [[ "$usezenity" == "false" ]]; then erase_title; choices+="Volume Label: $volname\n"; echo -en "$choices\n"; fi
(cd $resdir/Support; ./erasedisk.sh $system $tgtdsk $prtshm $fstyp $fmtyp $verbose $uefiboot "$volname" $setowner $usezenity "${udfdata[@]}")
}

fido_title () {
clear
echo "  Download an ISO file using Fido  "
echo "-----------------------------------"
}

fido_script () {
if [[ "$usezenity" == "false" ]]; then fido_title; fi
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
if   [[ "$usezenity" == "true" ]]; then
     choice=$(zenity --height="290" --width="200" --list --radiolist --title="Script Mode" --text="Please select how to run the script:" --hide-header --hide-column=2 --print-column=2 --column="Select" --column="ID" --column="Script Mode" FALSE 1 "Interactive Mode" FALSE 2 "CommandLine Mode")
     if [[ $? -ne 0 ]]; then return; fi
     read <<< $choice
else
     fido_title
     echo "Please select how to run the script:"
     echo " - Interactive Mode  (1)"
     echo " - CommandLine Mode  (2)"
     read -p "Please enter your choice to proceed: "
fi
case "$REPLY" in
     "1")  fido_mode="step" ;;
     "2")  fido_mode="cmds" ;;
      * )  select_err  ;;
esac
done
# Check if PowerShell is supported and run script.
version=$(pwsh -Version | awk '{print $NF}')
if   [[ "$usezenity" == "true" ]]; then
     zenfidoargs='--forms --title="Windows ISO Downloads" --text="Selection Options"'
else
     fido_prompt="Please enter your choice (q to Quit): "
fi
if  [ "$(printf '%s\n' "3.0" "$version" | sort -V | head -n1)" = "3.0" ]; then
    if   [[ "$fido_mode" == "step" ]]; then
         if   [[ "$usezenity" == "true" ]]; then
              versions=$(pwsh $resdir/Support/Fido.ps1 -Win List | tail -n +2)
              versions="${versions:2}"; versions=$(echo $versions | sed 's/ - /|/g')
              winverargs=" --add-combo=\"Downloads:\" --combo-values=\"$versions\""
              winver=$(eval zenity $zenfidoargs $winverargs)
              if   [[ $? -ne 0 ]]; then
                   winver="q"
              else
                   winverargs=" --add-combo=\"Downloads:\" --combo-values=\"$winver\""
              fi
         else
             fido_title
             pwsh $resdir/Support/Fido.ps1 -Win List
             read -p "$fido_prompt" winver
         fi
         if [[ "$winver" == "q" ]]; then return; fi
         if   [[ "$usezenity" == "true" ]]; then
              releases=$(pwsh $resdir/Support/Fido.ps1 -Win "$winver" -Rel List | tail -n +2)
              releases="${releases:2}"; releases=$(echo $releases | sed 's/ - /|/g')
              zenrelargs=" --add-combo=\"Releases:\" --combo-values=\"$releases\""
              release=$(eval zenity $zenfidoargs $winverargs $zenrelargs)
              if   [[ $? -ne 0 ]]; then
                   release="q"
              else
                   release=$(echo "$release" | awk -F'|' '{print $NF}')
                   zenrelargs=" --add-combo=\"Releases:\" --combo-values=\"$release\""
              fi
         else
             fido_title
             pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel List
             read -p "$fido_prompt" release
         fi
         if [[ "$release" == "q" ]]; then return; fi
         if   [[ "$usezenity" == "true" ]]; then
              editions=$(pwsh $resdir/Support/Fido.ps1 -Win "$winver" -Rel "$release" -Ed List | tail -n +2)
              editions="${editions:2}"; editions=$(echo $editions | sed 's/ - /|/g')
              zenedsargs=" --add-combo=\"Editions:\" --combo-values=\"$editions\""
              edition=$(eval zenity $zenfidoargs $winverargs $zenrelargs $zenedsargs)
              if   [[ $? -ne 0 ]]; then
                   edition="q"
              else
                   edition=$(echo "$edition" | awk -F'|' '{print $NF}')
                   zenedsargs=" --add-combo=\"Editions:\" --combo-values=\"$edition\""
              fi
         else
             fido_title
             pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed List
             read -p "$fido_prompt" edition
         fi
         if [[ "$edition" == "q" ]]; then return; fi
         if   [[ "$usezenity" == "true" ]]; then
              languages=$(pwsh $resdir/Support/Fido.ps1 -Win "$winver" -Rel "$release" -Ed "$edition" -Lang List | tail -n +2)
              languages="${languages:2}"; languages=$(echo $languages | sed 's/ - /|/g')
              zenlangargs=" --add-combo=\"Languages:\" --combo-values=\"$languages\""
              lang=$(eval zenity $zenfidoargs $winverargs $zenrelargs $zenedsargs $zenlangargs)
              if   [[ $? -ne 0 ]]; then
                   lang="q"
              else
                   lang=$(echo "$lang" | awk -F'|' '{print $NF}')
                   zenlangargs=" --add-combo=\"Languages:\" --combo-values=\"$lang\""
              fi
         else
             fido_title
             pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang List
             read -p "$fido_prompt" lang
         fi
         if [[ "$lang" == "q" ]]; then return; fi
         if   [[ "$usezenity" == "true" ]]; then
              architectures=$(pwsh $resdir/Support/Fido.ps1 -Win "$winver" -Rel "$release" -Ed "$edition" -Lang "$lang" -Arch List | tail -n +2)
              architectures="${architectures:2}"; architectures=$(echo $architectures | sed 's/,/|/g')
              zenarchargs=" --add-combo=\"Architectures:\" --combo-values=\"$architectures\""
              arch=$(eval zenity $zenfidoargs $winverargs $zenrelargs $zenedsargs $zenlangargs $zenarchargs)
              if   [[ $? -ne 0 ]]; then
                   arch="q"
              else
                   arch=$(echo "$arch" | awk -F'|' '{print $NF}')
                   zenarchargs=" --add-combo=\"Architectures:\" --combo-values=\"$arch\""
              fi
         else
             fido_title
             pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang $lang -Arch List
             read -p "$fido_prompt" arch
         fi
         if [[ "$arch" == "q" ]]; then return; fi
         cd ~/Downloads
         if   [[ "$usezenity" == "true" ]]; then
              (pwsh $resdir/Support/Fido.ps1 -Win "$winver" -Rel "$release" -Ed "$edition" -Lang "$lang" -Arch "$arch" && \
               pwsh -c "Write-Host "Download complete."") | zenity --width=750 --height=180 --text-info --title="Window ISO Downloads"
         else
             fido_title
             pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang $lang -Arch $arch
             sleep 1
         fi
         cd -
    elif [[ "$fido_mode" == "cmds" ]]; then
         if   [[ "$usezenity" == "true" ]]; then
              fido_args=$(zenity --width=500 --entry --title="Windows ISO Downloads" --text="Arguments:")
              if [[ $? -ne 0 ]]; then fido_args="q"; fi
         else
              fido_title
              read -p "Enter script arguments (q to Quit): " fido_args
         fi
         if [[ "$fido_args" == "q" ]]; then return; fi
         cd ~/Downloads
         if   [[ "$usezenity" == "true" ]]; then
              (pwsh $resdir/Support/Fido.ps1 $fido_args && pwsh -c "Write-Host "Download complete."") | \
              zenity --width=750 --height=180 --text-info --title="Window ISO Downloads"
         else
              fido_title
              pwsh $resdir/Support/Fido.ps1 $fido_args
              sleep 1
         fi
         cd -
    fi
else
    if   [[ "$usezenity" == "true" ]]; then
         zenity --error --title="PowerShell Error" --text="PowerShell version 3.0 or higher required."
    else
         fido_title
         echo "PowerShell version 3.0 or higher required."
         echo
         read -n 1 -s -r -p "Press any key to continue"
    fi
fi
}

checksum () {
clear
if [[ "$usezenity" == "false" ]]; then
   echo "     Verify SHA-1 checksum of an ISO file     "
   echo "----------------------------------------------"
fi
if   [[ "$usezenity" == "true" ]]; then
     file=$(zenity --file-selection --title="Select an ISO file" --file-filter="ISO Files|*.iso" 2> /dev/null)
     if [[ $? -ne 0 ]]; then return; fi
else
     read -p "Enter path to Windows ISO file: " file
fi
(
if [[ "$usezenity" == "true" ]]; then printf "# "; fi
echo "Calculating checksum..."
isosum=$(shasum "$file" | awk '{print $1}')
if [[ "$usezenity" == "true" ]]; then printf "# "; fi
echo "Searching on adguard.net..."
python3 -m webbrowser "https://sha1.rg-adguard.net/search.php?sha1=$isosum"
) | if [[ "$usezenity" == "true" ]]; then \
    zenity --progress --pulsate --title="Verify SHA-1 Checksum" --auto-close; else cat; fi
if [[ "$usezenity" == "false" ]]; then
   read -p "Press any key to continue... " -n1 -s
fi
}

extractdos () {
clear
if [[ "$usezenity" == "false" ]]; then
   echo "     Extract MS-DOS 8.0 files     "
   echo "----------------------------------"
fi
file="diskcopy.dll"
sym_server_agent='Microsoft-Symbol-Server/10.0.0.0'
diskcopy_url='https://msdl.microsoft.com/download/symbols/diskcopy.dll/54505118173000/diskcopy.dll'
# Microsoft symbol server curl reference: https://pete.akeo.ie/2024/06/downloading-signtoolexe.html
if   [[ ! -f $resdir/Support/diskcopy.dll && $have_msdos == "false" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          if   zenity --question --title="Download MS-DOS 8.0 Image" \
               --text="Would you like to download diskcopy.dll from Microsoft?"; then
               if ! curl -L -A $sym_server_agent $diskcopy_url -o $resdir/Support/diskcopy.dll 2> /dev/null; then
                    zenity --height=100 --width=250 --error --title="Download Failed" \
                    --text="Unable to download diskcopy.dll.\nPlease select the file and try again."
                    return
               fi
          else
               file=$(zenity --file-selection --title="Select the diskcopy library" --file-filter="DLL Files|*.dll" 2> /dev/null)
               if [[ $? -ne 0 ]]; then return; fi
          fi
     else
          read -p "Would you like to download diskcopy.dll from Microsoft [Y/N]? " getdcopy
          getdcopy=${getdcopy^^}
          while [[ $getdcopy != "Y" && $getdcopy != "N" ]]; do
                echo -e "${RED}Invalid entry. Try again.${NC}"
                read -p "Would you like to download diskcopy.dll from Microsoft [Y/N]? " getdcopy
                getdcopy=${getdcopy^^}
          done
          if   [[ $getdcopy == "Y" ]]; then
               if ! curl -L -A $sym_server_agent $diskcopy_url -o $resdir/Support/diskcopy.dll 2> /dev/null; then
                    echo "Unable to download diskcopy.dll."
                    echo "Please provide a path to the file."
                    echo
                    read -p "Press any key to continue... " -n1 -s
                    return
               fi
          else
               read -p "Enter path to diskcopy.dll: " file
               echo
          fi
     fi
elif [[ $have_msdos == "true" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          zenity --error --title="Actions Complete" --text="The MS-DOS files are already installed."
     else
          echo "The MS-DOS files are already installed."
          echo
          read -p "Press any key to continue... " -n1 -s
     fi
     return
fi

(cd $resdir/Support; ./extract_msdos.sh "$file" $usezenity)

if [[ $? -ne 0 ]]; then extdoserr="true"; else extdoserr="false"; fi

if [[ "$usezenity" == "true" ]]; then
   if   [[ $extdoserr == "true" ]]; then
        zenity --height=80 --width=230 --error --title="Installation Failed" \
               --text="MS-DOS files were not installed."
   else
        zenity --height=100 --width=230 --info --title="Installation Succeeded" \
               --text="MS-DOS files installed successfully."
   fi
fi
}

customize () {
clear
if [[ "$usezenity" == "false" ]]; then
   echo "    Customize your Windows Installation    "
   echo "-------------------------------------------"
fi
if   [[ "$system" == "Darwin" ]]; then
     read -p "Enter path to Windows disk [/Volumes/Windows]: " windisk
elif [[ "$system" == "Linux" ]]; then
     if   [[ "$usezenity" == "true" ]]; then
          windisk=$(zenity --file-selection --directory --title="Select the Windows drive" 2> /dev/null)
          if [[ $? -ne 0 ]]; then return; fi
     else
          read -p "Enter path to Windows disk [/media/$USER/Windows]: " windisk
     fi
fi
   
if [[ ! -d $windisk ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        zenity --error --title="Path Error" --text="Unable to access: $windisk."
   else
        echo
        echo "Unable to access path:" $windisk
        echo
        read -p "Press any key to continue... " -n1 -s
   fi
   return 1
fi

if   [[ -f "$windisk/sources/boot.wim" ]]; then
     winmedia="install"
elif [[ -f "$windisk/Windows/Boot/EFI/bootmgfw.efi" ]]; then
     winmedia="wintogo"
else
     if   [[ "$usezenity" == "true" ]]; then
          zenity --error --title="File Error" --text="Unable to locate the Windows files."
     else
          echo
          echo "Unable to locate the Windows files."
          echo
          read -p "Press any key to continue... " -n1 -s
     fi
     return 1
fi

if [[ "$usezenity" == "true" ]]; then
   zenwincustomargs='--list --checklist --width=480 --height=460 --title="BOOTDISK: Windows Customization" --text="Select from the options below:" --hide-header --hide-column=2 --column="Select" --column="Name" --column="Feature"'
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
    if   [[ "$usezenity" == "true" ]]; then
         if zenity --question --title="Windows Options" --text="Is this a Windows 11 disk?"; then eleven="Y"; else eleven="N"; fi
    else
         read -p "Is this a Windows 11 disk [Y/N]? " eleven
         eleven=${eleven^^}
         while [[ $eleven != "Y" && $eleven != "N" ]]; do
               echo -e "${RED}Invalid entry. Try again.${NC}"
               read -p "Is this a Windows 11 disk [Y/N]? " eleven
               eleven=${eleven^^}
         done
    fi
    if  [[ $eleven == "Y" ]]; then win11opts; fi
fi

localize="false"
settimezone="false"
useraccounts="false"
skipwifisetup="false"
disdatacol="false"
disautoenc="false"

if   [[ "$usezenity" == "true" ]]; then
     if [[ ! -z $(command -v pwsh) ]]; then zenwincustomargs+=' FALSE "usetimezone" "Use the current timezone setting on this system"'; fi
     zenwincustomargs+=' FALSE "uselocale" "Use the current language settings on this system" FALSE "newuser" "Create a local user account" FALSE "wifiscreen" "Skip the Join Wireless Network screen" FALSE "privacy" "Disable data collection and privacy questions" FALSE "bitlocker" "Disable BitLocker automatic drive encryption"'
     wincustopts=$(eval zenity $zenwincustomargs)
     IFS="|" read -a options <<< "$wincustopts"
     for item in "${options[@]}"; do
         case "$item" in
              "bypasshw")
                   unsupported="true"
                   ;;
              "msaccount")
                   bypassnro="true"
                   ;;
              "uselocale")
                   localize="true"
                   ;;
              "usetimezone")
                   settimezone="true"
                   ;;
              "wifiscreen")
                   skipwifisetup="true"
                   ;;
              "privacy")
                   disdatacol="true"
                   ;;
              "bitlocker")
                   disautoenc="true"
                   ;;
              "newuser")
                   useraccounts="true"
                   loginname=$(zenity --entry --title="Account Login Name" --text="Enter a login name for new account:" --entry-text="$USER")
                   if [[ $? -ne 0 ]]; then return; fi
                   fullname=$(zenity --entry --title="Account Full Name" --text="Enter the full name for new account:" --entry-text="$username")
                   if [[ $? -ne 0 ]]; then return; fi
                   description=$(zenity --entry --title="Account Description" --text="Enter a description for new account:")
                   if [[ $? -ne 0 ]]; then return; fi
                   ;;
         esac
     done
else
     read -p "Use the current language settings on this system [Y/N]? " uselocale
     uselocale=${uselocale^^}
     while [[ $uselocale != "Y" && $uselocale != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Use the current language settings on this system [Y/N]? " uselocale
      uselocale=${uselocale^^}
     done
     if  [[ $uselocale == "Y" ]]; then localize="true"; fi

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
         read -p "Enter the full name for new account [$username]: " fullname
         if [[ $fullname == "" ]]; then
            fullname="$username"
         fi
         read -p "Enter a description for new account: " description
     fi

     read -p "Skip the Join Wireless Network screen [Y/N]? " wifiscreen
     wifiscreen=${wifiscreen^^}
     while [[ $wifiscreen != "Y" && $wifiscreen != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Skip the Join Wireless Network screen [Y/N]? " wifiscreen
           wifiscreen=${wifiscreen^^}
     done
     if  [[ $wifiscreen == "Y" ]]; then skipwifisetup="true"; fi

     read -p "Disable data collection and privacy questions [Y/N]? " privacy
     privacy=${privacy^^}
     while [[ $privacy != "Y" && $privacy != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Disable data collection and privacy questions [Y/N]? " privacy
           privacy=${privacy^^}
     done
     if  [[ $privacy == "Y" ]]; then disdatacol="true"; fi

     read -p "Disable BitLocker automatic drive encryption [Y/N]? " bitlocker
     bitlocker=${bitlocker^^}
     while [[ $bitlocker != "Y" && $bitlocker != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Disable BitLocker automatic drive encryption [Y/N]? " bitlocker
           bitlocker=${bitlocker^^}
     done
     if  [[ $bitlocker == "Y" ]]; then disautoenc="true"; fi
fi

if  [[ $skipwifisetup == "true" || $disdatacol == "true" ]]; then oobe="true"; else oobe="false"; fi

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
   if   [[ "$usezenity" == "true" ]]; then
        if  [[ $wimtools == "true" && ! -z $(command -v hivexregedit) ]]; then
            if zenity --question --title="Windows Hardware Requirements" --text="Disable TPM, Secure Boot and RAM requirements?"; \
            then bypasshw="Y"; else bypasshw="N"; fi
        else
            zenwincustomargs+=' FALSE "bypasshw" "Disable TPM, Secure Boot and RAM requirements"'
        fi
   else
        read -p "Disable TPM, Secure Boot and RAM requirements [Y/N]? " bypasshw
        bypasshw=${bypasshw^^}
        while [[ $bypasshw != "Y" && $bypasshw != "N" ]]; do
              echo -e "${RED}Invalid entry. Try again.${NC}"
              read -p "Disable TPM, Secure Boot and RAM requirements [Y/N]? " bypasshw
              bypasshw=${bypasshw^^}
        done
   fi
   if  [[ $bypasshw == "Y" ]]; then
       if  [[ $wimtools == "true" && ! -z $(command -v hivexregedit) ]]; then
           (cd $resdir/Windows/Scripts; ./unsupported.sh "$windisk")
       else
           unsupported="true"
       fi
   fi
fi
if   [[ "$usezenity" == "true" ]]; then
     zenwincustomargs+=' FALSE "msaccount" "Disable requirement for an online Microsoft account"'
else
     read -p "Disable requirement for an online Microsoft account [Y/N]? " msaccount
     msaccount=${msaccount^^}
     while [[ $msaccount != "Y" && $msaccount != "N" ]]; do
           echo -e "${RED}Invalid entry. Try again.${NC}"
           read -p "Disable requirement for an online Microsoft account [Y/N]? " msaccount
           msaccount=${msaccount^^}
     done
fi
if  [[ $msaccount == "Y" ]]; then bypassnro="true"; fi
}

show_about () {
if   [[ "$usezenity" == "true" ]]; then
     if   [[ -f $docdir/bootdisk/About.html ]]; then
          about_path="$docdir/bootdisk/About.html"
     else
          about_path="$resdir/Support/About.html"
     fi
     if   [[ $(command -v xdg-open) ]]; then
          xdg-open "$about_path"
     else
          open "$about_path"
     fi
else
     clear
     cat $resdir/Support/About.txt
     echo
     read -n 1 -s -r -p "Press any key to continue"
fi
}

select_err () {
if   [[ "$usezenity" == "true" ]]; then
     zenity --error --title="Selection Error" --text="Please make a valid selection to proceed."
else
     echo "Invalid selection try again."
     sleep 1
fi
}

# Script starts here.
RED='\033[1;31m'
NC='\033[0m' # No Color
system=`uname`
text_mode="false"
usezenity="false"

#Check if zenity is installed and whether text mode is enabled.
if [[ "$1" == "--text-mode" || $system == "Darwin" ]]; then text_mode="true"; fi
if [[ ! -z $(command -v zenity) && "$text_mode" == "false" ]]; then usezenity="true"; fi

# Set resource location for supported platforms or exit.
if   [[ $system == "Darwin" ]]; then
     resdir="/opt/local/share/BOOTDISK"
elif [[ $system == "Linux" ]]; then
     resdir="/usr/local/share/BOOTDISK"
     docdir="/usr/share/doc"
else
     if   [[ "$usezenity" == "true" ]]; then
          zenity --error --title="Invalid Platform" \
          --text="This operating system is not supported."
     else
          echo "This operating system is not supported." >&2
     fi
     exit 1
fi

#Root privileges will only be used when needed.
if [[ $EUID -eq 0 ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        zenity --error --title="Privilege Elevation" \
        --text="This utility should NOT be run as root."
   else
        echo "This utility should NOT be run as root." >&2
   fi
   exit 1
fi

#Create a list of physical block devices for Zenity or text mode.
if   [[ "$usezenity" == "true" ]]; then
     zendevargs='--list --height=325 --width=500 --title="Select a Block Device" --column="Device" --column="Type" --column="Connection" --column="Size" --column="Description" --text="Choose a block device from the list:"'
     readarray -t devices <<< $(lsblk -dno name,type,tran,size,model | grep disk | awk '{printf("%s %s %4s %7s ", $1, $2, $3, $4); printf"\""; for (i = 5; i<= NF; i++) {printf "%s%s", $i, (i == NF ? "" : OFS);} printf "\"\n";}')
else
     if   [[ "$system" == "Darwin" ]]; then
          readarray -t physdisks <<< $(diskutil list physical | grep '0:' | awk '{print $NF}')
          for ((i = 0; i < ${#physdisks[@]}; i++))
          do
              readarray -O $i devlist <<< $(echo "${physdisks[$i]} $(diskutil info ${physdisks[$i]} | grep 'Device Location:' | awk '{print $3}') $(diskutil info ${physdisks[$i]} | grep 'Protocol:' | awk '{print $2}') $(diskutil info ${physdisks[$i]} | grep 'Disk Size:' | awk '{print $3,$4}' | sed 's/ //') $(diskutil info ${physdisks[$i]} | grep 'Device / Media Name:' | cut -d' ' -f14-)")
          done
          readarray devices <<< $(printf "%s" "${devlist[@]}" | awk 'BEGIN {n=1;} {printf("(%d) %s %s %4s %7s ",n++, $1, $2, $3, $4); printf"\""; for (i = 5; i<= NF; i++) {printf "%s%s", $i, (i == NF ? "" : OFS);} printf "\"\n";}')
          dev_menu_top='Select a block device:\n\nNum Drive     Type Conn    Size Description\n-------------------------------------'
     elif [[ "$system" == "Linux" ]]; then
          readarray devices <<< $(lsblk -dno name,type,tran,size,model | grep disk | awk 'BEGIN {n=1;} {printf("(%d) %s %s %4s %7s ",n++, $1, $2, $3, $4); printf"\""; for (i = 5; i<= NF; i++) {printf "%s%s", $i, (i == NF ? "" : OFS);} printf "\"\n";}')
          dev_menu_top='Select a block device:\n\nNum Blk Type Conn    Size Description\n-------------------------------------'
     fi
     dev_menu_btm='-------------------------------------'
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
if [[ ! -z "$missing" ]]; then
   if   [[ "$usezenity" == "true" ]]; then
        missing="$(sed 's/^[[:space:]]*//;s/ /, /g' <<< $missing)"
        zenity --error --title="Missing Dependencies" --text="The following packages are required: $missing"
   else
        missing="$(sed 's/^[[:space:]]*//' <<< $missing)"
        echo "The following packages are required: $missing"
   fi
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

# Check if the exfat utilities are installed.
if   [[ ! -z $(command -v mkfs.exfat) ]]; then
     exfat_make="true"
else
     exfat_make="false"
fi

# Check if the ntfs utilities are installed.
if [[ "$system" == "Darwin" ]]; then
   personality=$(diskutil listFilesystems | grep NTFS | awk '{print $1}')
fi
if   [[ ! -z $(command -v mkntfs) ]]; then
     ntfs_make="true"
else
     ntfs_make="false"
fi
if   [[ ! -z $(command -v ntfs-3g) ]]; then
     ntfs_progs="true"
else
     ntfs_progs="false"
fi

# Check if the UDF utilities are installed.
if   [[ ! -z $(command -v mkudffs) ]]; then
     udf_make="true"
else
     udf_make="false"
fi

# Check if wimlib and its tools are installed.
if  [[ ! -z $(command -v wimlib-imagex) ]]; then
    wimtools="true"
else
    wimtools="false"
fi

# Check if the MS-DOS system files are installed.
if   [[ -f $resdir/MS-DOS/Files/MSDOS.SYS && -f $resdir/MS-DOS/Files/IO.SYS &&
        -f $resdir/MS-DOS/Files/COMMAND.COM && -f $resdir/MS-DOS/Files/AUTOEXEC.BAT ]]; then
     have_msdos="true"
else
     have_msdos="false"
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

#Get full user name for use where needed.
if   [[ $system == "Darwin" ]]; then
     username=$(id -F)
elif [[ $system == "Linux" ]]; then
     username=$(getent passwd $USER | awk -F: '{print $5}')
fi

# Display menu for installed options.
if   [[ "$mtools" == "true" && "$biosmode" == "true" ]]; then
     if [[ $have_msdos == "true" ]]; then
	  menu_full
     else
	  menu_standard
     fi
else
	menu_default
fi
