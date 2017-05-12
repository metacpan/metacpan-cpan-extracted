#!/bin/csh

# this script copies all of the lexelt directories created by setup.pl
# into a LexSample directory

# this script is only called by setup.pl and is not intended to be
# use in a standalone fashion as a sample

if !(-e LexSample) then
	echo "Directory LexSample doesn't exist, aborting ..."
	exit 1;
endif

cd LexSample;
cd test-lexelts
set lexelts=`ls *.xml`
cd ..

foreach lexelt ($lexelts)
	set word=`echo $lexelt | sed 's/\-test//' | sed 's/\.xml//'`
	echo "Adding Lexelt $word to the LexSample"
	mkdir $word
	cp test-lexelts/$word*.xml $word/$word-test.xml
	cp test-lexelts/$word*.count $word/$word-test.count

	if(-e train-lexelts) then
		cp train-lexelts/$word*.xml $word/$word-training.xml
		cp train-lexelts/$word*.count $word/$word-training.count
	endif
end

rm -R test-lexelts

if(-e train-lexelts) then
	/bin/rm -R train-lexelts
endif

cd ..
