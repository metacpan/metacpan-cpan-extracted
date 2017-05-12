#!/bin/csh

echo "Test A2 for sval2plain.pl"
echo "Running sval2plain.pl test-A2.sval2"

sval2plain.pl test-A2.sval2 > test-A2.output

diff -w test-A2.output test-A2.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A2.output
 
