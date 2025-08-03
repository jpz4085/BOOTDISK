#!/usr/bin/env bash

platform=$(uname)

if [[ $# -eq 0 ]]; then
   echo "Usage: $(basename $0) install|uninstall|upgrade"
   exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

if   [[ "$platform" == "Linux" ]]; then
     bindir="/usr/local/bin"
     resdir="/usr/local/share/BOOTDISK"
elif [[ "$platform" == "Darwin" ]]; then
     bindir="/opt/local/bin"
     resdir="/opt/local/share/BOOTDISK"
else
     echo "Unsupported platform detected."
     exit 1
fi

if   [[ "$1" == "install" ]]; then
     echo "Installing scripts and resources..."
     install -d $bindir
     install -d $resdir/Support
     install -m 755 bootdisk.sh $bindir/bootdisk
     if [[ "$platform" == "Darwin" ]]; then
        install -m 755 Support/click_ignore.scpt $resdir/Support
     fi
     install -m 755 Support/*.sh $resdir/Support
     install -m 755 Support/modtime.py $resdir/Support
     install -m 644 Support/doslfn.zip $resdir/Support
     install -m 644 Support/About.txt $resdir/Support
     rsync -r --chmod=u=rwx,go=rx FreeDOS $resdir
     rsync -r --chmod=u=rwx,go=rx MS-DOS $resdir
     rsync -r --chmod=u=rwx,go=rx Windows $resdir
     chmod o+w $resdir/Support
     echo "Finished."
elif [[ "$1" == "uninstall" ]]; then
     echo "Removing scripts and resources..."
     rm $bindir/bootdisk
     rm -r $resdir
     echo "Finished."
elif [[ "$1" == "upgrade" ]]; then
     echo "Upgrading to current version..."
     rm $bindir/bootdisk
     rm $resdir/Support/About.txt
     rm $resdir/Windows/windowstogo.sh
     find $resdir -type f -name '*disk.sh' -delete
     find $resdir -type d -name 'Sectors' -prune -exec rm -rf {} \;
     install -m 755 bootdisk.sh $bindir/bootdisk
     install -m 755 FreeDOS/freedosdisk.sh $resdir/FreeDOS
     install -m 755 MS-DOS/msdosdisk.sh $resdir/MS-DOS
     install -m 755 Support/linuxotherdisk.sh $resdir/Support
     install -m 644 Support/About.txt $resdir/Support
     install -m 755 Windows/*.sh $resdir/Windows
     echo "Finished."
else
     echo "Invalid option entered. Please try again."
fi
