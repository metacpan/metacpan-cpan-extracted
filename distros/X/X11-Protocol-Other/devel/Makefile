# Copyright 2011, 2012, 2013, 2016 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

CFLAGS = -Wall -g -Wpadded
LOADLIBES = -lXss -lXi -lXv -lXxf86dga -lXext -lX11

pad:
	gcc -Wpadded -x c -fsyntax-only /usr/include/X11/extensions/xf86vmproto.h
	cd /usr/include/X11/extensions; \
	for i in *.h; do \
	  if egrep -q 'B32|B16' $$i; then \
	    echo '#include <stdio.h>'      >/tmp/$$i; \
	    echo '#include <X11/X.h>'     >>/tmp/$$i; \
	    echo '#include <X11/Xdefs.h>'     >>/tmp/$$i; \
	    echo '#include <X11/Xproto.h>'    >>/tmp/$$i; \
	    echo '#include <X11/Xprotostr.h>' >>/tmp/$$i; \
	    echo '#include <X11/Xmd.h>'       >>/tmp/$$i; \
	    cat $$i                           >>/tmp/$$i; \
	    gcc -Wpadded -fsyntax-only -x c /tmp/$$i; \
	  fi \
	done

# if grep -q 'Display *[*]' $$i; then :; else \

all: encode-emacs22.ctext encode-emacs22-ext.ctext \
	encode-emacs23.ctext encode-emacs23-ext.ctext \
	encode-xemacs21.ctext
# encode-emacs21.ctext encode-emacs21-ext.ctext \

encode-emacs21.ctext encode-emacs21-ext.ctext: encode-all.el
	emacs21 -q -batch -l encode-all.el -f my-ctext 
encode-emacs22.ctext encode-emacs22-ext.ctext: encode-all.el
	emacs22 -q -batch -l encode-all.el -f my-ctext 
encode-emacs23.ctext encode-emacs23-ext.ctext: encode-all.el
	emacs23 -q -batch -l encode-all.el -f my-ctext 
encode-xemacs21.ctext: encode-all.el
	xemacs21 -q -batch -l encode-all.el -f my-ctext 




encode-dump: encode-dump.c Makefile
	$(CC) $(CFLAGS) encode-dump.c -lX11 -o encode-dump

Encode-X11-xlib: Encode-X11-xlib.c Makefile
	$(CC) $(CFLAGS) Encode-X11-xlib.c -lX11 -o Encode-X11-xlib
Encode-X11-xlib2: Encode-X11-xlib2.c Makefile
	$(CC) $(CFLAGS) Encode-X11-xlib2.c -lX11 -o Encode-X11-xlib2


# render-extension.c
# LOADLIBES = -L /usr/X11R6/lib -lXrender -lX11
# CFLAGS = -g -O0
