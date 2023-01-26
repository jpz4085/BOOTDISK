# Language: Polish (MAZOVIA)
# Translated by Mateusz Viste
# Polish letters encoded in the MAZOVIA standard

# fatal errors
0.0:Brak pami�ci. Brakuje %ld bajt�w.\n
0.1:PAMI�� SYSTEMOWA ROZBITA! (b��d int 21.5803)\n
0.2:UMB Corruption: Chain doesn't reach top of low RAM at %dk. Last=0x%x.\n
0.3:The MCB chain is corrupted (no Z MCB after last M MCB, but %c at seg 0x%x).\n
0.4:Nieznany parametr: %s\nU�yj /? aby uzyska� pomoc\n
0.5:nieznana opcja: %s\n%s
0.6:The /NOSUMMARY option was specified, but no other output-producing options\nwere specified, so no output is being produced.\n%s
0.7:Fatal error: failed to free HMA, error code %02Xh\n
0.8:nieznana opcja (oczekiwano '/'): %s\n%s
0.9:Oczekiwano jakiej� warto�ci po /%s, a nie kolejnego parametru\n%s
0.10:Internal error: option '%s' has '%s' as a prefix\nplus another equal-length prefix
0.11:Internal error: option '%s' was an exact match for two\ndifferent switches\n
0.12:Error: option '%s' is ambiguous - it is a partial match for two\nor more different options\n%s
0.13:Oczekiwano jakiej� warto�ci po /%s\n%s
0.14:Niepoprawna opcja '%s': nale�y poda� conajmniej pierwsz� liter� nazwy opcji
# misc messages
1.0:Nieznany system operacyjny
1.1:%lu bajt�w\n
1.2:(%s bajt�w)\n
1.3: (%7s bajt�w)\n
1.4:Ostrze�enie: urz�dzenie zdaje si� nale�e� do paru blok�w pami�ci (%s\ni %s)\n
1.5:(no drv)
1.6:Brak wolnej pami�ci %s \n
1.7:%s nie jest obecnie w pami�ci.\n
1.8:%s u�ywa nast�puj�cej pami�ci:\n
1.9:%s Memory is not accessible\n
# memory types
2.0:Typ pami�ci         Suma      U�ytej     Wolnej\n
#   ----------------  --------   --------   --------
2.1:Konwencjonalna
2.2:UMB
2.3:Zarezerwowana
2.4:XMS
2.5:Ca�kowita pami��
2.6:Poni�ej 1 MB
2.7:Ca�kowitej EMS
2.8:Wolnej EMS
2.9:Najwi�kszy mo�liwy program wykonyw.
2.10:Najwi�kszy wolny blok pami�ci UMB
2.11:%s rezyduje w pami�ci HMA.\n
2.12:Dost�pne miejsce w pami�ci HMA
2.13:HMA is available via the XMS driver\n
2.14:HMA is not available via the XMS driver: not implemented by the driver\n
2.15:HMA is not available via the XMS driver: a VDISK device is present\n
2.16:HMA is not available via the XMS driver: HMA does not exist\n
2.17:HMA is not available via the XMS driver: HMA already in use\n
2.18:HMA is not available via the XMS driver: HMAMIN is larger than HMA\n
2.19:HMA is available via the XMS driver, minimum TSR size (HMAMIN): %u bytes\n
2.20:HMA is not available via the XMS driver: unknown error %02Xh\n
2.21:HMA is not available as no XMS driver is loaded\n
2.22:Memory accessible using Int 15h
2.23:Memory is not accessible using Int 15h (code %02xh)\n
# block types
3.0:
3.1:wolna
3.2:kod systemowy
3.3:dane systemowe
3.4:program
3.5:�rodowisko
3.6:pole danych
3.7:zarezerwowane
3.8:tablica przerwa�
3.9:pole danych BIOS
3.10:system data
3.11:sterownik urz�dzenia
3.12:obszar danych
3.13:IFS
3.14:(b��d)
# classify msgs
4.0:\nModu�y u�ywaj�ce pami�ci poni�ej 1 MB:\n\n
4.1:  Nazwa          Razem          Konwencjonalna       Pami�� UMB\n
#     --------  ----------------   ----------------   ----------------
4.2:SYSTEM
4.3:Wolna
4.4:\nSegment    Rozmiar ca�k.      Nazwa           Typ\n
#     -------  ----------------  ------------  -------------
4.5:\n    Adres     Atryb.   Nazwa      Program\n
#      -----------  ------ ----------  ----------
4.6:\nSegment       Razem\n
#     -------  ----------------
#            ----------------
4.7:Razem:
4.8:sterownik urz�dzenia systemowego\n
4.9:zainstalowane DEVICE=%s\n
4.10:%s Szczeg��y pami�ci:\n
4.11:Wolna pami�� %s:\n
4.12: (%u w tym bloku)

# EMS stuff
5.0:WEWN�TRZNY B��D EMS.\n
5.1:W systemie brak obecnie sterownika EMS.\n
5.2:\nWersja sterownika EMS
5.3:Ramka strony EMS
5.4:Ca�kowita pami�� EMS
5.5:Wolna pami�� EMS
5.6:Wszystkich uchwyt�w
5.7:Wolnych uchwyt�w
5.8:\n  Uchwyt  Strony   Rozmiar     Nazwa\n
#      -------- ------  --------   ----------
# XMS stuff
6.0:Sterownik XMS nie jest zainstalowany w systemie.\n
6.1:\nTestowanie pami�ci XMS...\n
6.2:WEWN�TRZNY B��D XMS.\n
6.3:INT 2F AX=4309 wspierane\n
6.4:Wersja XMS
6.5:Wersja sterownika XMS
6.6:status HMA
6.7:jest
6.8:nie ma
6.9:status linii A20
6.10:w��czone
6.11:wy��czone
6.12:Wolna pami�� XMS
6.13:Najwi�kszy wolny blok XMS
6.14:Wolnych uchwyt�w
6.15: Blok    Uchwyt    Rozmiar   Locks\n
#    ------- --------  --------  -------
6.16:Wolna pami�� UMB
6.17:Najwi�kszy wolny blok UMB
6.18:Pami�� UMB niedost�pna\n
# help message
7.0:FreeDOS MEM wersja %d.%d\n
7.1:Wy�wietla rozmiar wolnej i u�ytej pami�ci w systemie.
7.2:Sk�adnia: MEM [zero lub wi�cej opcji opisanych poni�ej]
7.3:/E          Wy�wietla wszystkie informacje na temat pami�ci EMS
7.4:/F          Przedstawia pe�n� list� blok�w pami�ci
7.5:/C          Klasyfikuje modu�y korzystaj�ce z pami�ci poni�ej 1 MB
7.6:/DEVICE     Wy�wietla list� sterownik�w obecnych w pami�ci
7.7:/U          Wy�wietla list� program�w w pami�ci konwencjonalnej i UMB
7.8:/X          Wy�wietla wszystkie informacje na temat pami�ci XMS
7.9:/P          Zatrzymuje si� po ka�dym pe�nym ekranie
7.10:/?          Wy�wietla niniejsz� pomoc
7.11:/DEBUG      Wy�wietla programy i sterowniki w pami�ci konwencjonalnej i UMB
7.12:/M <nazwa> | /MODULE <nazwa>\n            Wy�wietla ilo�� pami�ci u�ytej przez podany program lub sterownik
7.13:/FREE       Wy�wietla woln� pami�� konwencjonaln� i UMB (wy�sze bloki pami�ci)
7.14:/ALL        Wy�wietla szczeg��y o HMA (wysoki obszar danych)
7.15:/NOSUMMARY  Nie wy�wietla podsumowania kt�re normalnie ukazuje si� je�li\n            nie podano �adnych opcji
7.16:/SUMMARY    Neguje opcj� /NOSUMMARY
7.17:/%-10s Brak pomocy dla tej opcji\n
7.18:/OLD        Kompatybilno�� z FreeDOS MEM 1.7 beta
7.19:/D          Odpowiednik /DEBUG, chyba �e u�yto /OLD, to odpowiednik /DEVICE
7.20:/F          Odpowiednik /FREE, chyba �e u�yto /OLD, to odpowiednik /FULL
8.0:\nNaci�nij <Enter> aby kontynuowa� lub <Esc> by zako�czy�...
# Memory type names
9.0:Konwencjonalna
9.1:UMB
9.2:(b��d)
