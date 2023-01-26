# Messages used by pdTree v1 and FreeDOS tree 3.6
# Each line is limited to 159 characters unless MAXLINE is changed,
# but if possible should be limited to 79 per line, with a \n
# added to indicate go to next line, max 2 lines.
# The messages are split into sets,
# where each set corresponds to a given function in pdTree.
# Set 1, is for main and common strings.
# Many of the strings are used directly by printf,
# so when a %? appears, be sure any changes also include the %?
# where ? is a variable identifier and format.
# Note: only \\, \n, \r, \t are supported (and a single slash must use \\).
#
# common to many functions [Set 1]
1.1:\n
# main [Set 1] 
1.2:Kataloglistning\n
# Must include %s for label 
1.3:Kataloglistning f�r Volym %s\n
# Must include %s for serial #  
1.4:Volymens serienummer �r %s\n
1.5:Inga underkataloger existerar\n\n
# showUsage [Set 2] 
2.1:Visar en grafisk katalogstruktur f�r en enhet eller en s�kv�g.\n
# Each %c below will be replaced with proper switch/option
2.2:TREE [enhet:][s�kv�g] [%c%c] [%c%c]\n
2.3:   %c%c   Visa namnen f�r filerna i respektive katalog.\n
2.4:   %c%c   Anv�nd ASCII ist�llet f�r ut�kade tecken.\n
# showInvalidUsage [Set 3] 
# Must include the %s for option given.
3.1:Ogiltig flagga - %s\n
# The %c will be replaced with the primary switch (default is /)
3.2:Anv�nd TREE %c? f�r anv�ndningsinformation.\n
#showTooManyOptions
3.3:F�r m�nga parametrar - %s\n
# showVersionInfo [Set 4] 
# also uses treeDescription, message 2.1
4.1:Skrivet f�r att fungera med FreeDOS\n
4.2:Win32(c)-konsol och DOS med LFN-st�d.\n
# Must include the %s for version string. 
4.3:Version %s\n
4.4:Skrivet av: Kenneth J. Davis\n
4.5:Datum:      Augusti/September/Oktober/November, 2000; Januari, 2001\n
4.6:Kontakt:    jeremyd@computer.org\n
4.7:Copyright (c): Public Domain [definition enligt USA]\n
#4.8 is only used when cats support is compiled in.
4.8:Anv�nder Jim Halls <jhall@freedos.org> Cats-bibliotek\n  Copyright (C) 1999,2000,2001 Jim Hall\n
#4.20 20-30 reserved for FreeDOS tree derived from Dave Dunfield's tree
#4.20:Copyright 1995 Dave Dunfield - Freely distributable.\n
4.20:Copyright 1995, 2000 Dave Dunfield - Fritt distribuerbart (sl�ppt 200 som GPL).\n
# showInvalidDrive [Set 5] 
5.1:Ogiltig enhetsspecifikation\n
# showInvalidPath [Set 6] 
# Must include %s for the invalid path given. 
6.1:Ogiltig s�kv�g - %s\n
# misc error conditions [Set 7]
# showBufferOverrun
# %u required to show what the buffer's current size is. 
7.1:Fel: Angiven fils�kv�g �verskrider maximal buffert = %u byte\n
# showOutOfMemory
# %s required to display what directory we were processing when ran out of memory.
7.2:Slut p� minne vid underkatalog: %s\n
#
# parseArguments [Set 8] contains the Character[s] used for
#   argument processing.  Only the 1st character on a line is used.
#   Each argument is listed twice, the first is the uppercase version,
#   with the next entry being the lowercase version.
# Primary character used to determine option follows, default is '-'
8.1:/
# Secondary character used to determine option follows, default is '/'
8.2:-
# Indicates should show files
8.3:F
8.4:f
# Use ASCII only
8.5:A
8.6:a
# Show Version information
8.7:V
8.8:v
# DOS only version, Shortnames only (disable LFN support)
8.9:S
8.10:s
