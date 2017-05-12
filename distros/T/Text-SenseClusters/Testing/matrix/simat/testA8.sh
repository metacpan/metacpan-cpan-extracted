#!/bin/csh

echo "Test A8 for simat.pl"
echo "Running simat.pl --dense --format f6.3 test-A8.vec"

simat.pl --dense --format f6.3 test-A8.vec > test-A8.output

sort test-A8.output > t0
sort test-A8.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A8.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A8.output 
 
