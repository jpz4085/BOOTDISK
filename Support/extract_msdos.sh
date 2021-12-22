#!/bin/bash

help () {
    echo "Extract and patch embedded MS-DOS 8.0 files from diskcopy.dll"
    echo "Place the diskcopy.dll file in this folder and run this script."
    echo "Optional: run script with -x to only extract the floppy image."
    echo
    exit 0
}

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

echo
echo "***MS-DOS 8.0 File Extraction Script***"
echo

if [[ "$1" != "" && "$1" != "-x" || ! -e diskcopy.dll ]]; then
help
fi

imgsize=1474560
offset=`xxd -u -c 4 diskcopy.dll | grep 'EB3C 902A' | awk '{sub(/:$/,"",$1); print $1}' | (read hexoffset; printf "%d\n" 0x$hexoffset;)`
bytes=$(blocksize $offset $imgsize)
skip=$(($offset/$bytes))
count=$(($imgsize/$bytes))

echo "Extract floppy disk image..."
dd if=diskcopy.dll of=bootdisk.img bs=$bytes skip=$skip count=$count 2> /dev/null
if [[ "$1" == "-x" ]]; then
    echo
    echo "Finished!"
    echo
    exit 0
fi

echo "Extract and patch system files..."
7z x bootdisk.img -o../MS-DOS/Files > /dev/null
chmod -R 755 ../MS-DOS/Files
perl -i -pe 's|\x75\x10\xb8\x0e|\xeb\x10\xb8\x0e|sg' ../MS-DOS/Files/COMMAND.COM
perl -i -pe 's|\xfa\x80\x75\x09|\xfa\x80\xeb\x09|sg' ../MS-DOS/Files/IO.SYS
mkdir ../MS-DOS/Files/SYSTEM && mv ../MS-DOS/Files/{DISPLAY.SYS,EGA*.*,KEY*.*,MODE.COM} ../MS-DOS/Files/SYSTEM
touch -r ../MS-DOS/Files/MSDOS.SYS ../MS-DOS/Files/COMMAND.COM ../MS-DOS/Files/IO.SYS
printf '@echo off\r\nset PATH=.;\;\SYSTEM\r\n' > ../MS-DOS/Files/AUTOEXEC.BAT
echo "Delete floppy disk image..."
rm bootdisk.img
echo "Finished!"
echo
