#!/bin/csh

echo "Test A1 for reduce-count.pl"
echo "Running reduce-count.pl test-A1.bi test-A1.uni"

reduce-count.pl test-A1.bi test-A1.uni > test-A1.output

sort test-A1.output > t0
sort test-A1.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A1.output 
 
