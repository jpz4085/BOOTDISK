#!/usr/bin/env bash

#  bootdisk.sh - menus and options
#
#  Author: Joseph P. Zeller

title_block () {
cat<<EOF
===========================
    ---BOOTDISK v1.3---
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

menu_all () {
while :
do
clear
title_block
cat<<EOF
FreeDOS 1.3  (1)
MS-DOS  8.0  (2)
Windows 7-11 (3)
UEFI Shell   (4)
Tools Menu   (5)
About        (6)
Quit         (7)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  msdosdisk   ;;
"3")  windowsdisk ;;
"4")  uefi_shell  ;;
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
UEFI Shell   (3)
Tools Menu   (4)
About        (5)
Quit         (6)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  windowsdisk ;;
"3")  uefi_shell  ;;
"4")  menu_tools  ;;
"5")  show_about  ;;
"6")  exit        ;;
 * )  select_err  ;;
esac
done
}

menu_uefi () {
while :
do
clear
title_block
cat<<EOF
Windows 7-11 (1)
UEFI Shell   (2)
Tools Menu   (3)
About        (4)
Quit         (5)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  windowsdisk ;;
"2")  uefi_shell  ;;
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
Extract MS-DOS 8.0    (1)
Download an ISO file  (2)
Return to Main Menu   (3)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  extractdos  ;;
"2")  fido_script ;;
"3")  break       ;;
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
n=${#volname}
while [ $n -gt 11 ]; do
      echo -e "${RED}Label must be eleven characters or less.${NC}"
      read -p "Enter label [WINDOWS]: " volname
      n=${#volname}
done

echo
cd $resdir/FreeDOS && ./freedosdisk.sh $system $fstyp "$volname" $tgtdsk
cd ..
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
n=${#volname}
while [ $n -gt 11 ]; do
      echo -e "${RED}Label must be eleven characters or less.${NC}"
      read -p "Enter label [MSDOS80]: " volname
      n=${#volname}
done

echo
cd $resdir/MS-DOS && ./msdosdisk.sh $system $fstyp "$volname" $tgtdsk
cd ..
}

windowsdisk () {
clear
echo "     Windows Boot Disk Script      "
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

if [[ "$system" == "Darwin" ]]; then
    read -p "Enter file system [FAT32/EXFAT]: " fstyp
    fstyp=${fstyp^^}
    while [[ $fstyp != "FAT32" && $fstyp != "EXFAT" ]]; do
        echo -e "${RED}Invalid file system type. Try again.${NC}"
        read -p "Enter file system [FAT32/EXFAT]: " fstyp
        fstyp=${fstyp^^}
    done
elif [[ "$system" == "Linux" ]]; then
    read -p "Enter file system [FAT32/EXFAT/NTFS]: " fstyp
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
if [[ "$volname" == "" ]]; then volname=WINDOWS; fi
n=${#volname}
if [[ "$system" == "Darwin" || $fstyp == "FAT32" ]]; then
   while [ $n -gt 11 ]; do
       echo -e "${RED}Label must be eleven characters or less.${NC}"
       read -p "Enter label [WINDOWS]: " volname
       n=${#volname}
   done
elif [[ "$system" == "Linux" && $fstyp == "EXFAT" ]]; then
   while [ $n -gt 15 ]; do
         echo -e "${RED}Label must be fifteen characters or less.${NC}"
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
read -p "Enter ISO path [NONE]: " image
if [[ "$image" == "" ]]; then image=NONE; fi

echo
cd $resdir/Windows && ./windowsdisk.sh $system $prtshm $fstyp $uefint "$volname" "$image" $tgtdsk
cd ..
}

uefi_shell () {
clear
echo "      UEFI Shell Disk Script      "
echo "----------------------------------"
read -p "Wipe disk before extracting files [Y/N]? " wipe
wipe=${wipe^^}
while [[ $wipe != "Y" && $wipe != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Wipe disk before extracting files [Y/N]? " wipe
      wipe=${wipe^^}
done

if  [[ $wipe == "Y" ]]; then
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
    read -p "Enter partition scheme [GPT/MBR]: " prtshm
    prtshm=${prtshm^^}
    while [[ $prtshm != "GPT" && $prtshm != "MBR" ]]; do
          echo -e "${RED}Invalid partition scheme. Try again.${NC}"
          read -p "Enter partition scheme [GPT/MBR]: " prtshm
          prtshm=${prtshm^^}
    done
    read -p "Enter file system [FAT16/FAT32]: " fstyp
    fstyp=${fstyp^^}
    while [[ $fstyp != "FAT16" && $fstyp != "FAT32" ]]; do
          echo -e "${RED}Invalid file system type. Try again.${NC}"
          read -p "Enter file system [FAT16/FAT32]: " fstyp
          fstyp=${fstyp^^}
    done
    read -p "Enter label [UEFI_SHELL]: " volname
    if [[ "$volname" == "" ]]; then volname="UEFI_SHELL"; fi
    n=${#volname}
    while [ $n -gt 11 ]; do
          echo -e "${RED}Label must be eleven characters or less.${NC}"
          read -p "Enter label [UEFI_SHELL]: " volname
          n=${#volname}
    done
else
    if [[ "$system" == "Darwin" ]]; then
       read -p "Enter path to disk [/Volumes/Untitled]: " target
    elif [[ "$system" == "Linux" ]]; then
         read -p "Enter path to disk [/media/user/USB]: " target
    fi
    prtshm="CURRENT"
    fstyp="N/A"
    volname="N/A"
fi

read -p "Enter ISO path: " image
while [[ "$image" != *".iso"* ]]; do
      echo -e "${RED}Invalid file type. Try again.${NC}"
      read -p "Enter ISO path: " image
done

echo
cd $resdir/Support && ./uefishelldisk.sh $system "$image" "$target" $prtshm $fstyp "$volname"
cd ..
}

fido_script () {
clear
echo "  Download an ISO file using Fido  "
echo "-----------------------------------"
# Download script if missing or not current version.
if [[ ! -e $resdir/Support/Fido.ps1 || "$(grep "# Fido v" $resdir/Support/Fido.ps1 | tr -d [:alpha:]  | awk '{print $2}')" != "$fido_url_ver" ]]; then
   rm -f $resdir/Support/Fido.* 2> /dev/null && curl -Lo $resdir/Support/Fido.ps1.lzma $fido_url/download/Fido.ps1.lzma 2> /dev/null
   7z e $resdir/Support/Fido.ps1.lzma -o$resdir/Support/ > /dev/null && perl -i -pe's/"en-us"; Id = 0/"en-us"; Id = 1/' $resdir/Support/Fido.ps1
fi
# Check if PowerShell is supported and run script.
version=$(pwsh -Version | awk '{print $NF}')
if  [ "$(printf '%s\n' "3.0" "$version" | sort -V | head -n1)" = "3.0" ]; then
    pwsh $resdir/Support/Fido.ps1 -Win List
    read -p "Please enter your choice (q to Quit): " winver
    if [[ "$winver" == "q" ]]; then return; fi
    pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel List
    read -p "Please enter your choice (q to Quit): " release
    if [[ "$release" == "q" ]]; then return; fi
    pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed List
    read -p "Please enter your choice (q to Quit): " edition
    if [[ "$edition" == "q" ]]; then return; fi
    pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang List
    read -p "Please enter your choice (q to Quit): " lang
    if [[ "$lang" == "q" ]]; then return; fi
    pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang $lang -Arch List
    read -p "Please enter your choice (q to Quit): " arch
    if [[ "$arch" == "q" ]]; then return; fi
    cd ~/Downloads
    pwsh $resdir/Support/Fido.ps1 -Win $winver -Rel $release -Ed $edition -Lang $lang -Arch $arch
    sleep 1
    cd -
else
    echo "PowerShell version 3.0 or higher required."
    echo
    read -n 1 -s -r -p "Press any key to continue"
fi
}

extractdos () {
clear
echo "     Extract MS-DOS 8.0 files     "
echo "----------------------------------"
read -p "Enter path to diskcopy.dll: " file
echo
cd $resdir/Support && ./extract_msdos.sh "$file"
cd ..
}

show_about () {
clear
cat $resdir/Support/About.txt
echo
read -n 1 -s -r -p "Press any key to continue"
}

select_err () {
echo "Invalid selection try again."
}

RED='\033[1;31m'
NC='\033[0m' # No Color
system=`uname`
fido_url="https://github.com/pbatard/Fido/releases/latest"
fido_url_ver=$(curl -IkLs -o /dev/null -w %{url_effective} $fido_url | grep -o "[^/]*$"| sed "s/v//g")
uefint_url="https://raw.githubusercontent.com/pbatard/rufus/master/res/uefi/uefi-ntfs.img"
uefint_commit_url="https://api.github.com/repos/pbatard/rufus/commits?path=res/uefi/uefi-ntfs.img&page=1&per_page=1"
uefint_commit_date=$(curl -s $uefint_commit_url | jq -r '.[0].commit.committer.date' | cut -f1 -d"T")
uefint_image_date=$(stat -c '%y' $resdir/Support/uefi-ntfs.img 2> /dev/null | awk '{print $1}')

if [[ $system == "Darwin" ]]; then
   resdir="/opt/local/share/BOOTDISK"
else
   resdir="/usr/local/share/BOOTDISK"
fi

if [[ $system != "Darwin" && $system != "Linux" ]]; then
    echo "Unsupported platform detected."
    exit 1
fi

if [[ ! -e $resdir/Support/uefi-ntfs.img ]] || [[ $uefint_commit_date > $uefint_image_date ]; then
	rm -f $resdir/Support/uefi-ntfs.img 2> /dev/null
	curl -o $resdir/Support/uefi-ntfs.img $uefint_url 2> /dev/null
fi

if [[ $system == "Darwin" ]] || [[ $system == "Linux" && -e /usr/local/bin/ms-sys ]]; then
   if [[ -e $resdir/MS-DOS/Files/COMMAND.COM ]]; then
	menu_all
   else
	menu_standard
   fi
else
	menu_uefi
fi
