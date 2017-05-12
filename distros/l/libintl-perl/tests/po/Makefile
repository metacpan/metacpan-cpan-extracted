# Makefile for various po files.  This Makefile is intended for the
# maintainer.  No problem if you cannot run it on your system.

srcdir = .
top_srcdir = ..

LINGUAS = de de_AT xy xy_XY
PACKAGES = existing additional

#CATALOGS = $(addsuffix .po, LINGUAS)
CATALOGS = $(LINGUAS)
MO_FILES = $(foreach pkg,$(PACKAGES), $(addprefix $(pkg)., $(addsuffix .mo, $(LINGUAS))))

MSGMERGE = msgmerge
MSGFMT   = msgfmt
CATOBJEXT = .po

all: default

default: install 

install: $(MO_FILES)
	cd $(srcdir); \
	targetdir='$(top_srcdir)/LocaleData'; \
	languages='$(LINGUAS)'; \
	packages='$(PACKAGES)'; \
	for package in $$packages; do \
		for lang in $$languages; do \
			dest="$$targetdir/$$lang/LC_MESSAGES/$$package.mo"; \
			cat="$$package.$$lang.mo"; \
			echo "installing $$cat as $$dest"; \
			cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
		done; \
	done

update-mo: $(MO_FILES)
	@echo "MO-FILES: $(MO_FILES)"

clean:
	rm -f $(MO_FILES) *~

.SUFFIXES:
.SUFFIXES: .po .mo

.po.mo:
	$(MSGFMT) --check --statistics --verbose -o $@ $<

