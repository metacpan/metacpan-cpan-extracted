#!/bin/csh

echo "Test A3 for reduce-count.pl"
echo "Running reduce-count.pl test-A3.bi test-A3.uni"

reduce-count.pl test-A3.bi test-A3.uni > test-A3.output

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
 
