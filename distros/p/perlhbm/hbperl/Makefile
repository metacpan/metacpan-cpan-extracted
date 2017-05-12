HBCONFIG = hb-config
CC = gcc
CFLAGS = `$(HBCONFIG) --mod-cflags` `$(PERL) -MExtUtils::Embed -e ccopts` -I.
LDFLAGS = `$(HBCONFIG) --mod-ldflags` `$(PERL) -MExtUtils::Embed -e ldopts`
PERL = perl

perl.so: hbm_perl.o Makefile
	$(CC) hbm_perl.o -o perl.so $(LDFLAGS)

hbm_perl.o: Makefile hbm_perl.c perlxsi.c
	$(CC) -c hbm_perl.c $(CFLAGS)

clean:
	rm -f hbm_perl.o core *~

dist-clean:
	rm -f perl.so
