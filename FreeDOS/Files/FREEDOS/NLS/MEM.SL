# Translated by Matej Horvat (http://matejhorvat.si/), last update 2013-02-15

# fatal errors
0.0:Ni dovolj spomina. Potrebnih je �e %ld bajtov.\n
0.1:Sistemski pomnilnik uni�en! (napaka pri INT 21.5803)\n
0.2:UMB Corruption: Chain doesn't reach top of low RAM at %dk. Last=0x%x.\n
0.3:Veriga MCB je po�kodovana (ni Z bloka po zadnjem M bloku, toda %c na segmentu 0x%x).\n
0.4:Uporabite /? za pomo�.\n
0.5:neznana mo�nost: %s\n%s
0.6:Podana je bila mo�nost /NOSUMMARY, toda poleg nje �e nobena mo�nost, ki bi proizvajala izpis, zato izpisa ni.\n%s
0.7:Fatal error: failed to free HMA, error code %02Xh\n
0.8:neznana mo�nost (pri�akovan "/"): %s\n%s
0.9:Po /%s je pri�akovana vrednost in ne �e ena mo�nost\n%s
0.10:Internal error: option '%s' has '%s' as a prefix\nplus another equal-length prefix
0.11:Internal error: option '%s' was an exact match for two\ndifferent switches\n
0.12:Error: option '%s' is ambiguous - it is a partial match for two\nor more different options\n%s
0.13:Pri�akovana vrednost po /%s\n%s
0.14:Neveljavna mo�nost "%s"; podati morate vsaj eno �rko imena mo�nosti
# misc messages
1.0:Neznan operacijski sistem
1.1:%lu bajtov\n
1.2:(%s bajtov)\n
1.3: (%7s bajtov)\n
1.4:Opozorilo: naprava ima dva lastnika (%s in %s)\n
1.5:(ni pogonov)
1.6:%s spomin nima prostih blokov.\n
1.7:%s trenutno ni nalo�en.\n
1.8:%s uporablja naslednje spominske bloke:\n
1.9:%s spomin ni dosegljiv.\n
# memory types
2.0:Vrsta spomina      Skupaj    Zasedeno    Prosto\n
#   ----------------  --------   --------   --------
2.1:Navaden
2.2:Gornji
2.3:Rezerviran
2.4:Podalj�an (XMS)
2.5:Skupaj spomina
2.6:Skupaj pod 1 MB
2.7:Skupaj raz�irjenega (EMS)
2.8:Prosto raz�irjenega (EMS)
2.9:Najve�ja mo�na velikost programa
2.10:Najve�ji prost blok gornjega spomina
2.11:%s je nalo�en v HMA.\n
2.12:Prostor na voljo v HMA
2.13:HMA je na voljo preko gonilnika XMS\n
2.14:HMA preko gonilnika XMS ni na voljo: gonilnik tega ne podpira\n
2.15:HMA preko gonilnika XMS ni na voljo: prisotna je naprava VDISK\n
2.16:HMA preko gonilnika XMS ni na voljo: HMA ne obstaja\n
2.17:HMA preko gonilnika XMS ni na voljo: HMA je �e v rabi\n
2.18:HMA is not available via the XMS driver: HMAMIN is larger than HMA\n
2.19:HMA is available via the XMS driver, minimum TSR size (HMAMIN): %u bytes\n
2.20:HMA preko gonilnika XMS ni na voljo: neznana napaka %02Xh\n
2.21:HMA ni na voljo, ker ni nalo�en gonilnik XMS\n
2.22:Spomin, dostopen preko INT 15h
2.23:Spomin ni dostopen preko INT 15h (napaka %02xh)\n
# block types
3.0:
3.1:prosto
3.2:sistemska koda
3.3:sistemski podatki
3.4:program
3.5:okolje
3.6:podatki
3.7:rezervirano
3.8:prekinitveni vektorji
3.9:BIOS podatki
3.10:sistemski podatki
3.11:gonilnik
3.12:podatki
3.13:IFS
3.14:(napaka)
# classify msgs
4.0:\nModuli, ki uporabljajo spomin pod 1 MB:\n\n
4.1:  Ime            Skupaj         Navaden spomin     Gornji spomin\n
#     --------  ----------------   ----------------   ----------------
4.2:SISTEM
4.3:Prosto
4.4:\nSegment       Skupaj           Ime           Vrsta\n
#     -------  ----------------  ------------  -------------
4.5:\n   Naslov     Atrib.    Ime       Program\n
#      -----------  ------ ----------  ----------
4.6:\nSegment       Skupaj\n
#     -------  ----------------
#            ----------------
4.7:Skupaj:
4.8:sistemski gonilnik\n
4.9:nalo�en DEVICE=%s\n
4.10:%s spomin:\n
4.11:Prost %s spomin:\n
4.12: (%u v tem bloku)

# EMS stuff
5.0:Notranja napaka EMS!\n
5.1:Gonilnik za EMS ni name�en.\n
5.2:\nVerzija gonilnika EMS
5.3:EMS page frame
5.4:Skupaj EMS spomina
5.5:Prost EMS spomin
5.6:Skupaj oprimkov
5.7:Prostih oprimkov
5.8:\n  Handle  Strani  Velikost      Ime\n
#      -------- ------  --------   ----------
# XMS stuff
6.0:Gonilnik za XMS ni nalo�en.\n
6.1:\nPreizku�am XMS spomin...\n
6.2:Notranja napaka XMS!\n
6.3:Funkcija INT 2Fh AX=4309h je podprta.\n
6.4:Verzija XMS
6.5:Verzija gonilnika XMS
6.6:Stanje HMA
6.7:obstaja
6.8:ne obstaja
6.9:Stanje linije A20
6.10:omogo�ena
6.11:onemogo�ena
6.12:Prost XMS spomin
6.13:Najve�ji prost XMS blok
6.14:Prostih oprimkov
6.15: Blok    Handle   Velikost   Locks\n
#    ------- --------  --------  -------
6.16:Prost gornji spomin
6.17:Najve�ji gornji blok
6.18:Gornji spomin ni na voljo.\n
# help message
7.0:FreeDOS MEM, verzija %s
7.1:Prika�e koli�ino zasedenega in prostega spomina v sistemu.
7.2:Uporaba: MEM [mo�nosti]
7.3:/E             Sporo�i vse o raz�irjenem spominu (EMS).
7.4:/FULL          Prika�e celoten seznam spominskih blokov.
7.5:/C             Razvrsti module, ki uporabljajo spomin pod 1 MB.
7.6:/DEVICE        Prika�e seznam trenutno nalo�enih gonilnikov.
7.7:/U             Prika�e seznam programov v navadnem in gornjem spominu.
7.8:/X             Sporo�i vse o podalj�anem spominu (XMS).
7.9:/P             Se ustavi po vsakem zaslonu informacij.
7.10:/?             Prika�e to pomo�.
7.11:/DEBUG         Prika�e programe in naprave v navadnem in gornjem spominu.
7.12:/M[ODULE] ime  Prika�e spomin, ki ga uporablja dolo�en program ali gonilnik.
7.13:/FREE          Prika�e proste bloke v navadnem in gornjem spominu.
7.14:/ALL           Show all details of high memory area (HMA).
7.15:/NOSUMMARY     Ne prika�e povzetka, ki je navadno prikazan.
7.16:/SUMMARY       Zanika mo�nost /NOSUMMARY.
7.17:/%-10s Za to mo�nost pomo� ni na voljo.\n
7.18:/OLD           Zdru�ljivost s FreeDOS MEM 1.7 beta.
7.19:/D             Enako kot /DEBUG oz. /DEVICE v primeru /OLD.
7.20:/F             Enako kot /FREE oz. /FULL v primeru /OLD.
8.0:\nPritisnite Enter za nadaljevanje ali Esc za izhod
# Memory type names
9.0:navaden
9.1:gornji
9.2:(napaka)
