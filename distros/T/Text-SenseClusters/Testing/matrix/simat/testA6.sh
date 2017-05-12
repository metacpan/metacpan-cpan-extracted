#!/bin/csh

echo "Test A6 for simat.pl"
echo "Running simat.pl --dense --format f7.3 test-A6.vec"

simat.pl --dense --format f7.3 test-A6.vec > test-A6.output

sort test-A6.output > t0
sort test-A6.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A6.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A6.output 
 
