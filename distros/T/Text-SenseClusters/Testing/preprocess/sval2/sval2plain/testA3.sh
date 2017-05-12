#!/bin/csh

echo "Test A3 for sval2plain.pl"
echo "Running sval2plain.pl test-A3.sval2"

sval2plain.pl test-A3.sval2 > test-A3.output

diff -w test-A3.output test-A3.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A3.output
 
