#!/bin/csh
echo "Test 2 for balance.pl";
echo "Running balance.pl test-A2.xml 2";
balance.pl test-A2.xml 2 > test-A2.output
sort test-A2.output > t0
sort test-A2.reqd1 > t1
sort test-A2.reqd2 > t2
sort test-A2.reqd3 > t3
diff -w t0 t1 > v1
diff -w t0 t2 > v2
diff -w t0 t3 > v3
if(-z v1 || -z v2 || -z v3) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 t2 t3 v1 v2 v3 test-A2.output 
