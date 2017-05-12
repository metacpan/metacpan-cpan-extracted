# $Id: Makefile,v 1.1 1999/05/14 18:11:46 mpeppler Exp $
# from
#	@(#)Makefile	1.2	8/7/95
#

POD2MAN = pod2man
POD2HTML = pod2html
PERL = perl

all: man

POD = \
	sybperl.pod

MAN = \
	sybperl.man

HTML = \
	sybperl.html

man: $(MAN)

html: $(HTML)

.SUFFIXES: .pod .man

.pod.man:
	$(POD2MAN) $*.pod >$*.man

.SUFFIXES: .pod .html

.pod.html:
	$(POD2HTML) $*.pod >$*.html

clean:
	rm -f $(MAN) $(HTML) *~ *.ps

