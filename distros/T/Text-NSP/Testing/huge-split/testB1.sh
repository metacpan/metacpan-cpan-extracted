#!/bin/csh

echo "Test B1 for huge-split.pl"

echo "count.pl --newline --tokenlist test-1.output test-1.txt"
count.pl --newline --tokenlist test-1.output test-1.txt

echo "huge-split.pl test-1.output" 
huge-split.pl test-1.output 


if(-e test-1.out.1 ) then
	echo "Test Error";
else
	echo "Test OK";
endif

/bin/rm -f test-1.output
