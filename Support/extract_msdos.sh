#!/bin/bash

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

libfile="$1"
usegui="$2"

blocksize () {
    o=$1  # image offset
    s=$2  # image size
    r=1   # remainder

    until [ $r == 0 ]
    do
    let "r =$o % $s"
    o=$s
    s=$r
    done

    echo $o # block size as GCD
}

if  [[ -e "$libfile"  ]]; then
    hexoffset=`xxd -u -c 4 "$libfile" | grep 'EB3C 902A' | awk '{sub(/:$/,"",$1); print $1}'`
    if [[ ! $hexoffset ]]; then
       if [[ "$usegui" == "false" ]]; then
          echo "Unable to find floppy disk image in file."
          echo
          read -p "Press any key to continue... " -n1 -s
       fi
       exit 1
    fi
   
    offset=$(printf "%d\n" 0x$hexoffset;)
    imgsize=1474560
    bytes=$(blocksize $offset $imgsize)
    skip=$(($offset/$bytes))
    count=$(($imgsize/$bytes))

    if [[ "$usegui" == "false" ]]; then echo "Extract floppy disk image..."; fi
    dd if="$libfile" of=bootdisk.img bs=$bytes skip=$skip count=$count 2> /dev/null
    if [[ "$usegui" == "false" ]]; then echo "Extract and patch system files (sudo required)..."; fi
    if [[ "$usegui" == "true"  ]]; then
       zenity --password --title="Password Authentication" | sudo -Sv 2> /dev/null
       if [[ $? -ne 0 ]]; then rm -f bootdisk.img; exit 1; fi
    fi
    sudo 7z x bootdisk.img -o../MS-DOS/Files > /dev/null
    sudo chmod -R 755 ../MS-DOS/Files
    sudo chmod 644 ../MS-DOS/Files/MSDOS.SYS ../MS-DOS/Files/IO.SYS
    sudo perl -i -pe 's|\x75\x10\xb8\x0e|\xeb\x10\xb8\x0e|sg' ../MS-DOS/Files/COMMAND.COM
    sudo perl -i -pe 's|\xfa\x80\x75\x09|\xfa\x80\xeb\x09|sg' ../MS-DOS/Files/IO.SYS
    sudo mkdir ../MS-DOS/Files/SYSTEM && sudo mv ../MS-DOS/Files/{DISPLAY.SYS,EGA*.*,KEY*.*,MODE.COM} ../MS-DOS/Files/SYSTEM
    sudo touch -r ../MS-DOS/Files/MSDOS.SYS ../MS-DOS/Files/COMMAND.COM ../MS-DOS/Files/IO.SYS
    sudo 7z e doslfn.zip *.tbl *.gbk doslfn.com -o../MS-DOS/Files/SYSTEM > /dev/null
    printf '@echo off\r\nset PATH=.;\;\SYSTEM\r\nDOSLFN.COM\r\n' | sudo tee ../MS-DOS/Files/AUTOEXEC.BAT > /dev/null
    if [[ "$usegui" == "false" ]]; then echo "Delete floppy disk image..."; fi
    rm bootdisk.img
    if [[ "$usegui" == "false" ]]; then echo "Finished!"; fi
    if [[ "$usegui" == "false" ]]; then sleep 2; fi
    exit 0
else
    if [[ "$usegui" == "false" ]]; then
       echo "Unable to access the specified file."
       echo
       read -p "Press any key to continue... " -n1 -s
    fi
    exit 1
fi
