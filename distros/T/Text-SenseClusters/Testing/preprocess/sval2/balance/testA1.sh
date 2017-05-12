#!/bin/csh
echo "Test 1 for balance.pl";
echo "Running balance.pl test-A1.xml 1";
balance.pl test-A1.xml 1 > test-A1.output
sort test-A1.output > t0
sort test-A1.reqd1 > t1
sort test-A1.reqd2 > t2
sort test-A1.reqd3 > t3
sort test-A1.reqd4 > t4
diff -w t0 t1 > v1
diff -w t0 t2 > v2
diff -w t0 t3 > v3
diff -w t0 t4 > v4
if(-z v1 || -z v2 || -z v3 || -z v4) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 t2 t3 t4 v1 v2 v3 v4 test-A1.output
