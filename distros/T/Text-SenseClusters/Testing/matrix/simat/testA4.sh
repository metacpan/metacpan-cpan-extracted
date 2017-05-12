#!/bin/csh

echo "Test A4 for simat.pl"
echo "Running simat.pl --dense --format f2.0 test-A4.vec"

simat.pl --dense --format f2.0 test-A4.vec > test-A4.output

sort test-A4.output > t0
sort test-A4.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A4.output 
 
