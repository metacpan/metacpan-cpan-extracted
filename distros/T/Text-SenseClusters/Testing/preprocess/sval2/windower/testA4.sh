#!/bin/csh

echo "Test A4 for windower.pl"
echo "Running windower.pl --plain test-A4.input 5"

windower.pl --plain test-A4.input 5 > test-A4.output

diff -w test-A4.output test-A4.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4.reqd";
	cat var;
endif

/bin/rm -f var test-A4.output 
 
