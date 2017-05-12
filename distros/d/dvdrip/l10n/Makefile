# Makefile for various po files.

srcdir = .
libdir = ../lib

include PACKAGE

#CATALOGS = $(addsuffix .po, LINGUAS)
CATALOGS = $(LINGUAS)
MO_FILES = $(addsuffix .mo, $(LINGUAS))

MSGMERGE = msgmerge
MSGFMT   = msgfmt
XGETTEXT = xgettext
CATOBJEXT = .po

default: help

all: $(TEXTDOMAIN).pot update-po update-mo install

help:
	@echo "Available targets:"
	@echo "  pot                       - remake master catalog"
	@echo "  update-po                 - merge po files"
	@echo "  update-mo                 - regenerate mo files"
	@echo "  install                   - install mo files"
	@echo "  all			   - all of the above"

POTFILES = $(srcdir)/POTFILES.in \
	$(shell cat $(srcdir)/POTFILES.in) 

pot: $(TEXTDOMAIN).pot 

clean:
	rm -f *~ *.bak *.mo

# FIXME: The parameter --from-code is only needed if your sources contain
# any 8 bit data (even in comments).  UTF-8 is only a guess here, but it
# will at least accept any 8 bit data.
#
# The parameter "--language=perl" is not strictly needed because the
# source language of all our files will be auto-detected by xgettext
# by their filename extension.  You should even avoid this parameter
# if you want to extract strings from multiple source languages.
$(TEXTDOMAIN).pot: PACKAGE $(POTFILES)
	$(XGETTEXT) --output=$(srcdir)/$(TEXTDOMAIN).pox --from-code=UTF-8 \
		--add-comments=TRANSLATORS: --files-from=$(srcdir)/POTFILES.in \
		--copyright-holder="$(COPYRIGHT_HOLDER)" \
		--msgid-bugs-address="$(MSGID_BUGS_ADDRESS)" \
		--keyword --keyword='$$__' --keyword=__ --keyword=__x \
		--keyword=__n:1,2 --keyword=__nx:1,2 --keyword=__xn:1,2 \
		--keyword=N__ --language=perl && \
	rm -f $@ && mv $(TEXTDOMAIN).pox $@

install: $(MO_FILES)
	cd $(srcdir); \
	targetdir='$(libdir)/LocaleData'; \
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		mkdir -p "$$targetdir/$$lang/LC_MESSAGES" || exit 1; \
		dest="$$targetdir/$$lang/LC_MESSAGES/$(TEXTDOMAIN).mo"; \
		cat="$$lang.mo"; \
		echo "installing $$cat as $$dest"; \
		cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
	done
	touch .mo.installed
	cd ..; \
	tools/gensplash

update-mo: $(MO_FILES)

update-po:
	$(MAKE) $(TEXTDOMAIN).pot
	cd $(srcdir); \
        catalogs='$(CATALOGS)'; \
        for cat in $$catalogs; do \
          cat=`basename $$cat`; \
          lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
          mv $$lang.po $$lang.old.po; \
          echo "$$lang:"; \
          if $(MSGMERGE) $$lang.old.po $(TEXTDOMAIN).pot -o $$lang.po; then \
            rm -f $$lang.old.po; \
          else \
            echo "msgmerge for $$cat failed!"; \
            rm -f $$lang.po; \
            mv $$lang.old.po $$lang.po; \
          fi; \
        done

.SUFFIXES:
.SUFFIXES: .po .mo

.po.mo:
	$(MSGFMT) --check --statistics --verbose -o $@ $<

