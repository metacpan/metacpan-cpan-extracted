
LANGS	= en nl

all :
	for l in $(LANGS); do \
	  perl -w genhdr.pl -language $$l > hdrinfo-$$l.pl; \
	done

install :
	for l in $(LANGS); do \
	  install -m 0444 hdrinfo-$$l.pl ..; \
	done

clean :
	rm -f hdrinfo-*.pl
	rm -f *~
