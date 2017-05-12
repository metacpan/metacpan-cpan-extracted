#!/bin/csh

echo "Test A4 for reduce-count.pl"
echo "Running reduce-count.pl test-A4.bi test-A4.uni"

reduce-count.pl test-A4.bi test-A4.uni > test-A4.output

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

