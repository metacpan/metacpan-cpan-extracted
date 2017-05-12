# Installation directories
PREFIX ?= $(DESTDIR)
localedir = $(PREFIX)/usr/share/locale

PGOAL = urpmi

# perl files to search translatable strings in
PL_FILES = ../rpm-find-leaves ../urpm.pm ../urpme ../urpmf \
	../urpmi ../urpmi.addmedia ../gurpmi ../gurpmi2 ../gurpmi.pm \
	../urpmi.removemedia ../urpmi.update ../urpmq ../urpmi.recover \
	../urpm/*.pm ../rurpmi

POFILES = $(shell ls *.po)
MOFILES = $(POFILES:%.po=%.mo)
LANGS = $(POFILES:%.po=%)

GOALS = $(PGOAL).pot $(MOFILES)

all: $(GOALS)

%.mo: %.po
	msgfmt -o $@ $<

update_n_merge: $(PGOAL).pot merge

merge:
	@for n in $(POFILES); do \
	    echo "Merging $$n"; \
	    msgmerge "$$n" $(PGOAL).pot > "$$n"t; \
	    mv -f "$$n"t "$$n"; \
	done

$(PGOAL).pot: $(PL_FILES)
	intltool-update --gettext-package desktopstuff --pot
	perl_checker -q --generate-pot $(PGOAL)_tmp.pot $(PL_FILES)
	[ ! -e $(PGOAL)_tmp.pot ] || msgcat --use-first $(PGOAL)_tmp.pot desktopstuff.pot > $@
	rm -f desktopstuff.pot $(PGOAL)_tmp.pot 

install: all
	for l in $(LANGS); do \
	    install -d $(localedir)/$$l/LC_MESSAGES; \
	    install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(PGOAL).mo; \
	done

clean:
	@rm -rf *~ *.mo $(GOALS) $(PGOAL)_tmp.pot

test:

realclean: clean
