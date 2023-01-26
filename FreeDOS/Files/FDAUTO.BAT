@ECHO OFF

set DOSDRV=C:
set DOSDIR=C:\FreeDOS
set PATH=%dosdir%\BIN
set NLSPATH=%dosdir%\NLS
set TEMP=%dosdir%\TEMP
set TMP=%TEMP%
set DIRCMD=/P /OGN /Y /LFN
set COPYCMD=/-Y
set OS_NAME=FreeDOS
set OS_VERSION=1.3
alias reboot=fdapm warmboot
alias shutdown=fdapm poweroff

LH FDAPM APMDOS
LH DOSLFN.COM

