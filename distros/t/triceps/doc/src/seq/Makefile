SRCS      = $(wildcard *.txt)
TARGETS   = $(notdir $(SRCS:.txt=.xml))

all : $(TARGETS)

clean:
	rm -f *.xml *.tmp

%.xml: %.txt formseq.pl Makefile
	./formseq.pl $(<:.txt=) < $< > $@.tmp
	mv $@.tmp $@
