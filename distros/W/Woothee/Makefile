all: test

.PHONY: install

install:
	cpanm Carton
	carton install

testsets:
	git submodule update --init

lib/Woothee/DataSet.pm: install
	carton exec perl maint/dataset_yaml2pm.pl
	sync; sync; sync;

test: install lib/Woothee/DataSet.pm
	test -d t/testsets || mkdir t/testsets
	cp woothee/testsets/*.yaml t/testsets
	carton exec prove -Ilib
