#!/bin/csh

echo "Test A7 for simat.pl"
echo "Running simat.pl --dense --format f9.5 test-A7.vec"

simat.pl --dense --format f9.5 test-A7.vec > test-A7.output

sort test-A7.output > t0
sort test-A7.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A7.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A7.output 
 
