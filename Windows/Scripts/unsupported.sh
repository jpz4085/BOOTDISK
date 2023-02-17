#!/usr/bin/env bash

#  unsupported.sh - Disable Windows 11 hardware checks.
#  
#
#  Created by Joseph P. Zeller.

hivepath="Windows/System32/config/SYSTEM"

echo "Extracting registry hive from Windows PE image..."
wimextract "$1"/sources/boot.wim 2 $hivepath --dest-dir /tmp &> /dev/null
echo "Disable TPM/Secure Boot/RAM requirements..."
reged -C -I /tmp/SYSTEM SYSTEM Disable_Hardware_Checks.reg | tee /dev/null > /dev/null
echo "Replace registry hive in Windows PE image..."
wimupdate "$1"/sources/boot.wim 2 --command "add /tmp/SYSTEM $hivepath" &> /dev/null
rm /tmp/SYSTEM
