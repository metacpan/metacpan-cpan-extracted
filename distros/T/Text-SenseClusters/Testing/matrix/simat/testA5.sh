#!/bin/csh

echo "Test A5 for simat.pl"
echo "Running simat.pl --dense --format f7.3 test-A5.vec"

simat.pl --dense --format f7.3 test-A5.vec > test-A5.output

sort test-A5.output > t0
sort test-A5.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A5.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A5.output 
 
