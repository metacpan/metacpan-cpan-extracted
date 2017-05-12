#!/bin/csh

echo "Test A1 for windower.pl"
echo "Running windower.pl test-A1.input 5"

windower.pl test-A1.input 5 > test-A1.output

diff -w test-A1.output test-A1.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f var test-A1.output 
 
