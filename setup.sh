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
     homedir="$(getent passwd $SUDO_USER | cut -d: -f6)"
     apphome="$homedir/.local/share/applications"
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
     if   [[ "$platform" == "Darwin" ]]; then
          install -m 755 Support/click_ignore.scpt $resdir/Support
     elif [[ "$platform" == "Linux" ]]; then
          install -m 755 Support/bootdisk.desktop "$apphome"
          chown $SUDO_USER:$SUDO_USER "$apphome/bootdisk.desktop"
          if   [[ -d "$homedir/snap/firefox" ]]; then
               install -d /usr/share/doc/bootdisk
               install -m 644 Support/About.html /usr/share/doc/bootdisk
          else
               install -m 644 Support/About.html $resdir/Support
          fi
     fi
     install -m 755 Support/*.sh $resdir/Support
     install -m 755 Support/modtime.py $resdir/Support
     install -m 644 Support/doslfn.zip $resdir/Support
     install -m 644 Support/About.txt $resdir/Support
     install -m 644 Support/usb-icon.png $resdir/Support
     rsync -r --chmod=u=rwx,go=rx FreeDOS $resdir
     rsync -r --chmod=u=rwx,go=rx MS-DOS $resdir
     rsync -r --chmod=u=rwx,go=rx Windows $resdir
     chmod o+w $resdir/Support
     echo "Finished."
elif [[ "$1" == "uninstall" ]]; then
     echo "Removing scripts and resources..."
     rm $bindir/bootdisk
     rm -r $resdir
     if [[ "$platform" == "Linux" ]]; then
        rm "$apphome/bootdisk.desktop"
        rm -rf /usr/share/doc/bootdisk
     fi
     echo "Finished."
elif [[ "$1" == "upgrade" ]]; then
     echo "Upgrading to current version..."
     rm $bindir/bootdisk
     rm -f $resdir/Support/About.*
     rm $resdir/Windows/windowstogo.sh
     find $resdir -type f -name '*disk.sh' -delete
     find $resdir -type d -name 'Sectors' -prune -exec rm -rf {} \;
     install -m 755 bootdisk.sh $bindir/bootdisk
     install -m 755 FreeDOS/freedosdisk.sh $resdir/FreeDOS
     install -m 755 MS-DOS/msdosdisk.sh $resdir/MS-DOS
     install -m 755 Windows/*.sh $resdir/Windows
     install -m 755 Support/*.sh $resdir/Support
     install -m 644 Support/usb-icon.png $resdir/Support
     install -m 644 Support/About.txt $resdir/Support
     if [[ "$platform" == "Linux" ]]; then
        install -m 755 Support/bootdisk.desktop "$apphome"
        chown $SUDO_USER:$SUDO_USER "$apphome/bootdisk.desktop"
        if   [[ -d "$homedir/snap/firefox" ]]; then
             rm -rf /usr/share/doc/bootdisk
             install -d /usr/share/doc/bootdisk
             install -m 644 Support/About.html /usr/share/doc/bootdisk
        else
             install -m 644 Support/About.html $resdir/Support
        fi
     fi
     echo "Finished."
else
     echo "Invalid option entered. Please try again."
fi
