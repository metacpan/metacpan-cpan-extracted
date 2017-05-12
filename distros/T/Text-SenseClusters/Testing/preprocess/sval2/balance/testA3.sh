#!/bin/csh
echo "Test 3 for balance.pl";
echo "Running balance.pl test-A3.xml 2";
balance.pl test-A3.xml 2 > test-A3.output
sort test-A3.output > t0
sort test-A3.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 v1 test-A3.output 
