#!/usr/bin/env bash

#  bootdisk.sh - menus and options
#
#  Author: Joseph P. Zeller

title_block () {
cat<<EOF
===========================
    ---BOOTDISK v1.5---
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
Extract MS-DOS 8.0          (1)
Download an ISO file        (2)
Custom Windows installation (3)
Return to Main Menu         (4)
EOF
lower_border
read -p"Enter Choice: "
case "$REPLY" in
"1")  extractdos  ;;
"2")  fido_script ;;
"3")  customize   ;;
"4")  break       ;;
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
    volname=${volname^^}
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
         read -p "Enter path to disk [/media/user/USBDISK]: " target
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
(cd $resdir/Support; ./uefishelldisk.sh $system "$image" "$target" $prtshm $fstyp "$volname")
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
   perl -i -pe's/Start-BitsTransfer -Source \$Url -Destination/Invoke-WebRequest -UseBasicParsing -Uri \$Url -OutFile/' $resdir/Support/Fido.ps1 # Use Invoke-WebRequest for ISO downloads since BITS is not available on Unix.
fi
# Check if PowerShell is supported and run script.
version=$(pwsh -Version | awk '{print $NF}')
fido_prompt="Please enter your choice (q to Quit): "
if  [ "$(printf '%s\n' "3.0" "$version" | sort -V | head -n1)" = "3.0" ]; then
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
(cd $resdir/Support; ./extract_msdos.sh "$file")
}

customize () {
clear
echo "    Customize Windows Installation Media    "
echo "--------------------------------------------"
if   [[ "$system" == "Darwin" ]]; then
     read -p "Enter path to install disk [/Volumes/Untitled]: " windisk
elif [[ "$system" == "Linux" ]]; then
     read -p "Enter path to install disk [/media/user/USBDISK]: " windisk
fi
   
if [[ ! -d $windisk ]]; then
   echo
   echo "Unable to access path:" $windisk
   echo
   read -p "Press any key to continue... " -n1 -s
   return 1
fi

unsupported="false"
bypassnro="false"
# Check for Windows 11 media and provide options to disable hardware and Microsoft account requirements.
if [[ $wimtools == "true" ]]; then
    if  [[ $(wiminfo "$windisk"/sources/install.* 1 | grep -m 1 Name: | sed "s/^.*: *//") == "Windows 11"* ]]; then win11opts; fi
else
    read -p "Is this a Windows 11 install disk [Y/N]? " eleven
    eleven=${eleven^^}
    while [[ $eleven != "Y" && $eleven != "N" ]]; do
          echo -e "${RED}Invalid entry. Try again.${NC}"
          read -p "Is this a Windows 11 install disk [Y/N]? " eleven
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
if [[ $(command -v pwsh) != "" ]]; then
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

if  [[ $unsupported == "false" && $localize == "false" ]]; then
    mkdir -p "$windisk/sources/\$OEM\$/\$\$/Panther"
    xmlpath="$windisk/sources/\$OEM\$/\$\$/Panther/unattend.xml"
else
    xmlpath="$windisk/autounattend.xml"
fi

(cd $resdir/Windows/Scripts; ./unattend.sh $unsupported $localize $bypassnro $oobe $settimezone $useraccounts $skipwifisetup $disdatacol $disautoenc "$loginname" "$fullname" "$description" > "$xmlpath")
}

win11opts () {
read -p "Disable TPM, Secure Boot and RAM requirements [Y/N]? " bypasshw
bypasshw=${bypasshw^^}
while [[ $bypasshw != "Y" && $bypasshw != "N" ]]; do
      echo -e "${RED}Invalid entry. Try again.${NC}"
      read -p "Disable TPM, Secure Boot and RAM requirements [Y/N]? " bypasshw
      bypasshw=${bypasshw^^}
done
if  [[ $bypasshw == "Y" ]]; then
    if  [[ $wimtools == "true" && $(command -v reged) != "" ]]; then
        (cd $resdir/Windows/Scripts; ./unsupported.sh "$windisk")
    else
        unsupported="true"
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
if [[ $(command -v 7z) == "" ]]; then missing+=" p7zip"; fi
if [[ $(command -v jq) == "" ]]; then missing+=" jq"; fi
if [[ $(command -v curl) == "" ]]; then missing+=" curl"; fi
if [[ $system == "Linux" && $(command -v mkntfs) == "" ]]; then missing+=" ntfs-3g"; fi
if [[ $system == "Linux" && $(command -v mkfs.exfat) == "" ]]; then missing+=" exfatprogs"; fi
if [[ $system == "Linux" && $(command -v mount.exfat-fuse) == "" ]]; then missing+=" exfat-fuse"; fi
if [[ $system == "Darwin" ]]; then
   bashver=$(bash --version | head -n 1 | awk '{print $4}' | cut -f1 -d'(')
   if  [ "$(printf '%s\n' "3.2.57" "$bashver" | sort -rV | head -n1)" == "3.2.57" ]; then
       missing+=" bash(>$bashver)"
   fi
fi
if [[ $system == "Darwin" ]] || [[ $system == "Linux" && -e /usr/local/bin/ms-sys ]]; then
   if [[ $(command -v mtools) == "" ]]; then
      missing+=" mtools"
   fi
fi
if [[ "$missing" != "" ]]; then
   echo "The following packages are required:""$missing"
   exit 1
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

# Determine if wimlib and its tools are installed.
if  [[ $(command -v wimlib-imagex) == "" ]]; then
    wimtools="false"
else
    wimtools="true"
fi

# Display menu for available options.
if [[ $system == "Darwin" ]] || [[ $system == "Linux" && -e /usr/local/bin/ms-sys ]]; then
   if [[ -e $resdir/MS-DOS/Files/COMMAND.COM ]]; then
	menu_all
   else
	menu_standard
   fi
else
	menu_uefi
fi
