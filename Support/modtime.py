#!/usr/bin/python3

import os
import time
import sys

# Read file modification time and display in ISO 8601 format.
path = sys.argv[1]
mod_ti = time.ctime(os.path.getmtime(path))
T_stamp = time.strftime("%Y-%m-%d %H:%M:%S", time.strptime(mod_ti))

print(f"{T_stamp}")
