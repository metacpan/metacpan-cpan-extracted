#!/bin/csh

echo "Test A3 for simat.pl"
echo "Running simat.pl --dense --format f2.0 test-A3.vec"

simat.pl --dense --format f2.0 test-A3.vec > test-A3.output

sort test-A3.output > t0
sort test-A3.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A3.output 
 
