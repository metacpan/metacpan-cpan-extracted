#!/bin/csh

echo "Test B1 for sval2plain.pl"
echo "Running sval2plain.pl test-B1.sval2"

sval2plain.pl test-B1.sval2 > test-B1.output

if(-z test-B1.output) then
	echo "Test Ok";
else
	echo "Test Error";
	cat test-B1.output;
endif

/bin/rm -f test-B1.output
 
