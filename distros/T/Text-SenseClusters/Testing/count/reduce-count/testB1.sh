#!/bin/csh

echo "Test B1 for reduce-count.pl"
echo "Running reduce-count.pl test-B1.bi test-B1.uni"

reduce-count.pl test-B1.bi test-B1.uni >& test-B1.output

sort test-B1.output > t0
sort test-B1.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B1.output 
 
