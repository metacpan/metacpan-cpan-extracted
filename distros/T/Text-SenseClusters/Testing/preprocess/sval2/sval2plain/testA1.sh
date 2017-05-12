#!/bin/csh

echo "Test A1 for sval2plain.pl"
echo "Running sval2plain.pl test-A1.sval2"

sval2plain.pl test-A1.sval2 > test-A1.output

diff -w test-A1.output test-A1.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A1.output
 
