#!/bin/csh

echo "Test A3 for windower.pl"
echo "Running windower.pl --token test-A3.token --target test-A3.target test-A3.input 5"

windower.pl --token test-A3.token --target test-A3.target test-A3.input 5 > test-A3.output

diff -w test-A3.output test-A3.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var;
endif

/bin/rm -f var test-A3.output 
 
