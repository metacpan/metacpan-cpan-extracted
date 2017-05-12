#!/bin/csh

echo "Test A2 for reduce-count.pl"
echo "Running reduce-count.pl test-A2.bi test-A2.uni"

reduce-count.pl test-A2.bi test-A2.uni > test-A2.output

sort test-A2.output > t0
sort test-A2.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A2.output 
 
