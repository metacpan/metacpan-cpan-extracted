.PHONY: all pdf html

all: pdf html

pdf: refs genrefs.pl
	[ -d pdf ] || mkdir pdf
	./genrefs.pl pdf < refs

html: refs genrefs.pl
	[ -d html ] || mkdir html
	./genrefs.pl html < refs

clean:
	rm -rf pdf html
