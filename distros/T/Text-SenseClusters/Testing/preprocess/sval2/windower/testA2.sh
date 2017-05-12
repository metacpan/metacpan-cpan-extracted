#!/bin/csh

echo "Test A2 for windower.pl"
echo "Running windower.pl --token test-A2.token --target test-A2.target test-A2.input 5"

windower.pl --token test-A2.token --target test-A2.target test-A2.input 5 > test-A2.output

diff -w test-A2.output test-A2.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f var test-A2.output 
 
