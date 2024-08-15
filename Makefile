# BOOTDISK v1.6
#
# Makefile for Darwin and Linux
#

OS := $(shell uname)

ifeq ($(OS),Darwin)
	PREFIX ?= /opt/local
	CFLAGS = -target x86_64-apple-macos10.6
else
	PREFIX ?= /usr/local
endif

BINDIR = $(PREFIX)/bin
RESDIR = $(PREFIX)/share/BOOTDISK

all:
ifeq ($(OS),Darwin)
	$(MAKE) exfatboot
endif

install:
	install -d $(BINDIR)
	install -d $(RESDIR)/Support
	install -m 755 bootdisk.sh $(BINDIR)/bootdisk
ifeq ($(OS),Darwin)
        ifneq (,$(wildcard Support/exfatboot))
	install -m 755 Support/exfatboot $(BINDIR)
        endif
	install -m 755 Support/click_ignore.scpt $(RESDIR)/Support
endif
	install -m 755 Support/extract_msdos.sh $(RESDIR)/Support
	install -m 755 Support/uefishelldisk.sh $(RESDIR)/Support
	install -m 755 Support/modtime.py $(RESDIR)/Support
	install -m 644 Support/doslfn.zip $(RESDIR)/Support
	install -m 644 Support/About.txt $(RESDIR)/Support
	rsync -r --chmod=u=rwx,go=rx FreeDOS $(RESDIR)
	rsync -r --chmod=u=rwx,go=rx MS-DOS $(RESDIR)
	rsync -r --chmod=u=rwx,go=rx Windows $(RESDIR)
	chmod o+w $(RESDIR)/Support

uninstall:
	$(RM) $(BINDIR)/bootdisk
ifeq ($(OS),Darwin)
        ifneq (,$(wildcard $(BINDIR)/exfatboot))
	$(RM) $(BINDIR)/exfatboot
        endif
endif
	$(RM) -r $(RESDIR)

update:
	$(RM) $(BINDIR)/bootdisk
	$(RM) $(RESDIR)/Support/About.txt
	$(RM) $(RESDIR)/Support/extract_msdos.sh
	$(RM) $(RESDIR)/Support/Fido.*
	$(RM) $(RESDIR)/Windows/Scripts/*.sh
	$(RM) $(RESDIR)/Windows/Scripts/*.reg
	$(RM) $(RESDIR)/Windows/windowstogo.sh
	find $(RESDIR) -type f -name '*disk.sh' -delete
	install -m 755 bootdisk.sh $(BINDIR)/bootdisk
	install -m 755 FreeDOS/freedosdisk.sh $(RESDIR)/FreeDOS
	install -m 755 MS-DOS/msdosdisk.sh $(RESDIR)/MS-DOS
	install -m 644 Support/About.txt $(RESDIR)/Support
	install -m 755 Support/uefishelldisk.sh $(RESDIR)/Support
	install -m 755 Support/extract_msdos.sh $(RESDIR)/Support
	install -m 755 Windows/windowsdisk.sh $(RESDIR)/Windows
	install -m 755 Windows/windowstogo.sh $(RESDIR)/Windows
	install -m 755 Windows/Scripts/unattend.sh $(RESDIR)/Windows/Scripts
	install -m 755 Windows/Scripts/unsupported.sh $(RESDIR)/Windows/Scripts
	install -m 644 Windows/Scripts/Disable_Hardware_Checks.reg $(RESDIR)/Windows/Scripts
	install -m 644 Windows/Scripts/Disable_Internal_Drives.reg $(RESDIR)/Windows/Scripts
clean:
ifeq ($(OS),Darwin)
	$(RM) Support/exfatboot
endif

exfatboot: %: Support/%.c
	$(CC) -o Support/$@ $^ $(CFLAGS)
