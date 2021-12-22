#!/bin/bash

#  bootdisk.sh - menu/input script
#
#  Author: Joseph P. Zeller
#

menu1 () {
while :
do
clear
cat<<EOF
===========================
    ---BOOTDISK v1.0---
Flash Drive Formatting Tool
===========================
Select an option:

FreeDOS 1.2  (1)
MS-DOS  8.0  (2)
Windows 7-10 (3)
About        (4)
Quit         (5)
===========================
EOF
read -p"Enter Choice: "
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  msdosdisk   ;;
"3")  windowsdisk ;;
"4")  show_about  ;;
"5")  exit        ;;
 * )  select_err  ;;
esac
sleep 1
done
}

menu2 () {
while :
do
clear
cat<<EOF
===========================
    ---BOOTDISK v1.0---
Flash Drive Formatting Tool
===========================
Select an option:

FreeDOS 1.2  (1)
Windows 7-10 (2)
About        (3)
Quit         (4)
===========================
EOF
read -p"Enter Choice: "
case "$REPLY" in
"1")  fdosdisk    ;;
"2")  windowsdisk ;;
"3")  show_about  ;;
"4")  exit        ;;
 * )  select_err  ;;
esac
sleep 1
done
}

menu3 () {
while :
do
clear
cat<<EOF
===========================
    ---BOOTDISK v1.0---
Flash Drive Formatting Tool
===========================
Select an option:

Windows 7-10 (1)
About        (2)
Quit         (3)
===========================
EOF
read -p"Enter Choice: "
case "$REPLY" in
"1")  windowsdisk ;;
"2")  show_about  ;;
"3")  exit        ;;
 * )  select_err  ;;
esac
sleep 1
done
}

fdosdisk () {
clear
echo "   FreeDOS 1.2 Boot Disk Script    "
echo "-----------------------------------"
read -p "Enter target disk [disk#/sd*]: " tgtdsk
while [[ $tgtdsk != *"disk"* && $tgtdsk != *"sd"* ]]; do
    echo "Invalid target disk. Try again."
    read -p "Enter target disk [disk#/sd*]: " tgtdsk
done

read -p "Enter file system [FAT16/FAT32]: " fstyp
while [[ $fstyp != "FAT16" && $fstyp != "FAT32" ]]; do
    echo "Invalid file system type. Try again."
    read -p "Enter file system [FAT16/FAT32]: " fstyp
done

read -p "Enter label [FREEDOS]: " volname
if [[ "$volname" == "" ]]; then volname=FREEDOS; fi

echo
cd $resdir/FreeDOS && ./freedosdisk.sh $system $fstyp "$volname" $tgtdsk
cd ..
}

msdosdisk () {
clear
echo "    MS-DOS 8.0 Boot Disk Script    "
echo "-----------------------------------"
read -p "Enter target disk [disk#/sd*]: " tgtdsk
while [[ $tgtdsk != *"disk"* && $tgtdsk != *"sd"* ]]; do
    echo "Invalid target disk. Try again."
    read -p "Enter target disk [disk#/sd*]: " tgtdsk
done

read -p "Enter file system [FAT16/FAT32]: " fstyp
while [[ $fstyp != "FAT16" && $fstyp != "FAT32" ]]; do
    echo "Invalid file system type. Try again."
    read -p "Enter file system [FAT16/FAT32]: " fstyp
done

read -p "Enter label [MSDOS80]: " volname
if [[ "$volname" == "" ]]; then volname=MSDOS80; fi

echo
cd $resdir/MS-DOS && ./msdosdisk.sh $system $fstyp "$volname" $tgtdsk
cd ..
}

windowsdisk () {
clear
echo "     Windows Boot Disk Script      "
echo "-----------------------------------"
read -p "Enter target disk [disk#/sd*]: " tgtdsk
while [[ $tgtdsk != *"disk"* && $tgtdsk != *"sd"* ]]; do
    echo "Invalid target disk. Try again."
    read -p "Enter target disk [disk#/sd*]: " tgtdsk
done

if [[ "$system" == "Darwin" ]]; then
    read -p "Enter file system [FAT32/EXFAT]: " fstyp
    while [[ $fstyp != "FAT32" && $fstyp != "EXFAT" ]]; do
        echo "Invalid file system type. Try again."
        read -p "Enter file system [FAT32/EXFAT]: " fstyp
    done
elif [[ "$system" == "Linux" ]]; then
    read -p "Enter file system [FAT32/EXFAT/NTFS]: " fstyp
    while [[ $fstyp != "FAT32" && $fstyp != "EXFAT" && $fstyp != "NTFS" ]]; do
        echo "Invalid file system type. Try again."
        read -p "Enter file system [FAT32/EXFAT/NTFS]: " fstyp
    done
fi
    
if [[ $fstyp == "EXFAT" || $fstyp == "NTFS" ]] && [[ -e $resdir/Support/uefi-ntfs.img ]]; then
    read -p "Enable UEFI boot support [Y/N]? " uefint
    while [[ $uefint != "Y" && $uefint != "N" ]]; do
        echo "Invalid entry. Try again."
        read -p "Enable UEFI boot support [Y/N]? " uefint
    done
else
    uefint="N"
fi

read -p "Enter label [WINDOWS]: " volname
if [[ "$volname" == "" ]]; then volname=WINDOWS; fi
read -p "Enter ISO path [NONE]: " image
if [[ "$image" == "" ]]; then image=NONE; fi

echo
cd $resdir/Windows && ./windowsdisk.sh $system $fstyp $uefint "$volname" "$image" $tgtdsk
cd ..
}

show_about () {
clear
cat $resdir/Support/Readme.txt
echo
read -n 1 -s -r -p "Press any key to continue"
}

select_err () {
echo "Invalid selection try again."
}

system=`uname`
uefint_url="https://raw.githubusercontent.com/pbatard/rufus/master/res/uefi/uefi-ntfs.img"

if [[ $system == "Darwin" ]]; then
   resdir="/opt/local/share/BOOTDISK"
else
   resdir="/usr/local/share/BOOTDISK"
fi

if [[ $system != "Darwin" && $system != "Linux" ]]; then
    echo "Unsupported platform detected."
    exit 1
fi

if [[ ! -e $resdir/Support/uefi-ntfs.img ]]; then
	curl -o $resdir/Support/uefi-ntfs.img $uefint_url 2> /dev/null
fi

if [[ $system == "Darwin" ]] || [[ $system == "Linux" && -e /usr/local/bin/ms-sys ]]; then
   if [[ -e $resdir/MS-DOS/Files/COMMAND.COM ]]; then
	menu1
   else
	menu2
   fi
else
	menu3
fi
