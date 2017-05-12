BSTs := $(notdir $(basename $(wildcard ../bibstyle/*.bst)))
BBLs = $(BSTs:=.bbl)

default: $(BBLs)

%.bbl:	%.aux
	env BSTINPUTS=../bibstyle BIBINPUTS=../bibs bibtex $*

%.aux:
	@echo '\citation{*}'         >  $@
	@echo '\bibdata{xampl}'      >> $@
	@echo '\bibstyle{$*}'        >> $@

peek:
	@echo $(BBLs)
