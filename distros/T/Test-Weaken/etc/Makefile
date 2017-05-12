
.PHONY: build display

build:
	(cd ..;perl Makefile.PL)
	(cd ..;make realclean)
	(cd ..;perl Makefile.PL)
	(cd ..;make)
	(cd ..;make test)
	(cd ..;make disttest)

display: display.errs

# check displays
display.errs:
	perl display_test.pl > $@
	wc -l $@
