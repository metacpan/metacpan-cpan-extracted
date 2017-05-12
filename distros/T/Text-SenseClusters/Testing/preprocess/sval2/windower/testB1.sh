#!/bin/csh

echo "Test B1 for windower.pl"
echo "Running windower.pl test-B1.input 5"

windower.pl test-B1.input 5 >& test-B1.output

diff -w test-B1.output test-B1.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f var test-B1.output
/bin/rm -f tempfile*.windower 
 
