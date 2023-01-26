# Language: Polish (MAZOVIA)
# Translated by Mateusz Viste
# Polish letters encoded in the MAZOVIA standard
#
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
1.2:Katalogowanie �cie�ek folder�w\n
# Must include %s for label 
1.3:Katalogowanie �cie�ek folder�w dla zbioru %s\n
# Must include %s for serial #  
1.4:Numer seryjny zbioru to %s\n
1.5:Nie ma �adnego podkatalogu\n\n
# showUsage [Set 2] 
2.1:Graficznie przedstawia struktur� dysku lub katalogu.\n
# Each %c below will be replaced with proper switch/option
2.2:TREE [dysk:][�cie�ka] [%c%c] [%c%c]\n
2.3:   %c%c   Wy�wietla nazwy plik�w znajduj�cych si� w ka�dym katalogu.\n
2.4:   %c%c   U�ywa ASCII zamiast rozszerzonych znak�w.\n
# showInvalidUsage [Set 3] 
# Must include the %s for option given.
3.1:Niepoprawny parametr - %s\n
# The %c will be replaced with the primary switch (default is /)
3.2:U�yj TREE %c? aby otrzyma� informacje na temat obs�ugi.\n
#showTooManyOptions
3.3:Zbyt wiele parametr�w - %s\n
# showVersionInfo [Set 4] 
# also uses treeDescription, message 2.1
4.1:Napisany by wsp��pracowa� z FreeDOS\n
4.2:konsol� Win32(c) i DOS ze wsparciem LFN.\n
# Must include the %s for version string. 
4.3:Wersja %s\n
4.4:Napisa�: Kenneth J. Davis\n
4.5:Data:       Sierpie�/Wrzesie�/Pa�dziernik/Listopad, 2000; Stycze�, 2001\n
4.6:Kontakt:    jeremyd@computer.org\n
4.7:Copyright (c): Public Domain [United States Definition]\n
#4.8 u�ywany jest wy��cznie gdy cats jest w niego wkompilowany.
4.8:Korzysta z biblioteki Cats Jim'a Hall'a <jhall@freedos.org>\n  Copyright (C) 1999,2000,2001 Jim Hall\n
#4.20 20-30 reserved for FreeDOS tree derived from Dave Dunfield's tree
#4.20:Copyright 1995 Dave Dunfield - Bezp�atnie rozpowszechniany.\n
4.20:Copyright 1995, 2000 Dave Dunfield - Bezp�atny (od roku 2000 jako GPL).\n
# showInvalidDrive [Set 5] 
5.1:Niepoprawne oznaczenie dysku\n
# showInvalidPath [Set 6] 
# Must include %s for the invalid path given. 
6.1:Niepoprawna �cie�ka - %s\n
# misc error conditions [Set 7]
# showBufferOverrun
# %u required to show what the buffer's current size is. 
7.1:B��d: �cie�ka pliku przekracza maksymalny bufor = %u bytes\n
# showOutOfMemory
# %s required to display what directory we were processing when ran out of memory.
7.2:Zabrak�o pami�ci przy katalogu: %s\n
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
8.3:P
8.4:p
# Use ASCII only
8.5:A
8.6:a
# Show Version information
8.7:W
8.8:w
# DOS only version, Shortnames only (disable LFN support)
8.9:K
8.10:k
