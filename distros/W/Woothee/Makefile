all: test

.PHONY: install

install:
	cpanm Carton
	carton install

testsets:
	git submodule update --init

checkyaml: install testsets
	carton exec perl woothee/bin/dataset_checker.pl

lib/Woothee/DataSet.pm: install checkyaml
	carton exec perl maint/dataset_yaml2pm.pl
	sync; sync; sync;

test: install lib/Woothee/DataSet.pm
	test -d t/testsets || mkdir t/testsets
	cp woothee/testsets/*.yaml t/testsets
	carton exec prove -Ilib
