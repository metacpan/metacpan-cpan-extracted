#!/bin/csh

echo "Test A5 for windower.pl"
echo "Running windower.pl --token test-A5.token --target test-A5.target --plain test-A5.input 5"

windower.pl --plain --token test-A5.token --target test-A5.target test-A5.input 5 > test-A5.output

diff -w test-A5.output test-A5.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A5.reqd";
	cat var;
endif

/bin/rm -f var test-A5.output 
 
