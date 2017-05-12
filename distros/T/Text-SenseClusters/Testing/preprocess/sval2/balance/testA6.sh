#!/bin/csh
echo "Test 6 for balance.pl";
echo "Running balance.pl test-A6.xml 2";
balance.pl test-A6.xml 2 > test-A6.output
sort test-A6.output > t0
sort test-A6.reqd > t1

diff -w t0 t1 > v1

if(-z v1) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 v1 test-A6.output 
