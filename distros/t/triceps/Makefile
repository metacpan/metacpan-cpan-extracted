
.DEFAULT_GOAL = all

all clean test qtest vtest: perl/Triceps/Makefile
	LANG=C $(MAKE) -C cpp $@
	LANG=C $(MAKE) -C perl/Triceps $@

clobber:
	$(MAKE) -C cpp $@
	$(MAKE) -C perl/Triceps $@

install: all
	$(MAKE) -C perl/Triceps $@ DESTDIR='$(DESTDIR)'

uninstall:
	$(MAKE) -C perl/Triceps $@ DESTDIR='$(DESTDIR)'

perl/Triceps/Makefile: perl/Triceps/Makefile.PL
	cd perl/Triceps && perl Makefile.PL

release:
	./mkrelease
