#!/bin/csh

echo "Test B2 for windower.pl"
echo "Running windower.pl test-B2.input 5"

windower.pl test-B2.input 5 >& test-B2.output

diff -w test-B2.output test-B2.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat var;
endif

/bin/rm -f var test-B2.output 
/bin/rm -f tempfile*.windower 
 
