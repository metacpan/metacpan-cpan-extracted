# Makefile -- Makefile for mh_doc package
# RCS Status      : $Id$
# Author          : Johan Vromans
# Created On      : Sun Sep  9 13:35:04 1990
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jan 11 16:12:55 2003
# Update Count    : 140
# Status          : OK

VERSION	   = 1.902

prefix     = /usr
bindir     = /usr/bin
datadir    = /usr/share
libdir     = /usr/lib
sysconfdir = /etc

INSTALL	   = install

all :
	rm -f mmds
	echo "#!/bin/sh" >mmds
	echo "MMDSLIB=$(libdir)/mmds" >>mmds
	echo "export MMDSLIB" >>mmds
	echo 'PATH=$$MMDSLIB:$$PATH; export PATH' >>mmds
	echo 'exec perl $$MMDSLIB/`basename $$0`.pl $${1+"$$@"}' >>mmds
	mkdir examples
	mv testfonts.txt examples

install :
	mkdir -p $(bindir)
	$(INSTALL) -m 0555 mmds $(bindir)/mmds
	mkdir -p $(libdir)/mmds
	$(INSTALL) -m 0664 mmds.prp $(libdir)/mmds
	$(INSTALL) -m 0775 *.pl mmds mmdscvt $(libdir)/mmds
	find MMDS -type d ! -name RCS -printf "mkdir -p $(libdir)/mmds/%p\n" | sh 
	find MMDS -name '*.pm' -printf "$(INSTALL) -m 0664 %p $(libdir)/mmds/%p\n" | sh 
	mkdir -p $(datadir)/mmds/texdir
	$(INSTALL) -m 0664 latex/mmds_doc.cls latex/mmds_doc.pro $(datadir)/mmds/texdir

tardist :
	cd ..; \
	find core \( -name '*~' -o -name '#.*#' -o -name 'x.*' \) -exec rm -f {} \; ; \
	rm -f mmds-$(VERSION); \
	ln -s core mmds-$(VERSION); \
	find mmds-$(VERSION)/ -type f -print | egrep -v '(OLD|RCS)' | \
	tar -zcvf mmds-$(VERSION).tar.gz -T -

clean :
