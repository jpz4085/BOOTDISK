#!/usr/bin/env bash

#  unsupported.sh - Disable Windows 11 hardware checks.
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

hivepath="Windows/System32/config/SYSTEM"

echo "Extracting registry hive from Windows PE image..."
wimextract "$1"/sources/boot.wim 2 $hivepath --dest-dir /tmp &> /dev/null
echo "Disable TPM/Secure Boot/RAM requirements..."
hivexregedit --merge --prefix SYSTEM /tmp/SYSTEM Disable_Hardware_Checks.reg
echo "Replace registry hive in Windows PE image..."
wimupdate "$1"/sources/boot.wim 2 --command "add /tmp/SYSTEM $hivepath" &> /dev/null
rm /tmp/SYSTEM
