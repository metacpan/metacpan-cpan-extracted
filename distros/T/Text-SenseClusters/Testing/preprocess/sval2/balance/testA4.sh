#!/bin/csh
echo "Test 4 for balance.pl";
echo "Running balance.pl test-A4.xml 1";
balance.pl test-A4.xml 1 > test-A4.output
sort test-A4.output > t0
sort test-A4.reqd1 > t1
sort test-A4.reqd2 > t2
diff -w t0 t1 > v1
diff -w t0 t2 > v2
if(-z v1 || -z v2) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 v1 t2 v2 test-A4.output 
