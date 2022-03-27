# BOOTDISK v1.1
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
	install -m 755 Support/exfatboot $(BINDIR)
	install -m 755 Support/click_ignore.scpt $(RESDIR)/Support
endif
	install -m 755 Support/extract_msdos.sh $(RESDIR)/Support
	install -m 644 Support/Readme.txt $(RESDIR)/Support
	rsync -r --chmod=u=rwx,go=rx FreeDOS $(RESDIR)
	rsync -r --chmod=u=rwx,go=rx MS-DOS $(RESDIR)
	rsync -r --chmod=u=rwx,go=rx Windows $(RESDIR)
	chmod o+w $(RESDIR)/Support

uninstall:
	$(RM) $(BINDIR)/bootdisk
ifeq ($(OS),Darwin)
	$(RM) $(BINDIR)/exfatboot
endif
	$(RM) -r $(RESDIR)

update:
	$(RM) $(BINDIR)/bootdisk
	$(RM) $(RESDIR)/Support/Readme.txt
	find $(RESDIR) -type f -name '*disk.sh' -delete
	install -m 755 bootdisk.sh $(BINDIR)/bootdisk
	install -m 755 FreeDOS/freedosdisk.sh $(RESDIR)/FreeDOS
	install -m 755 MS-DOS/msdosdisk.sh $(RESDIR)/MS-DOS
	install -m 644 Support/Readme.txt $(RESDIR)/Support
	install -m 755 Windows/windowsdisk.sh $(RESDIR)/Windows

clean:
ifeq ($(OS),Darwin)
	$(RM) Support/exfatboot
endif

exfatboot: %: Support/%.c
	$(CC) -o Support/$@ $^ $(CFLAGS)
