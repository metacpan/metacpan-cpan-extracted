#!/bin/csh

echo "Test A9 for simat.pl"
echo "Running simat.pl --format f8.3 --dense test-A9.vec"

simat.pl --format f8.3 --dense test-A9.vec > test-A9.output

sort test-A9.output > t0
sort test-A9.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A9.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A9.output 
 
