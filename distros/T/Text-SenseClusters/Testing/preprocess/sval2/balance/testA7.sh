#!/bin/csh
echo "Test A7  for balance.pl";
echo "Running balance.pl test-A7.xml 2";
balance.pl test-A7.xml 2 > test-A7.output
sort test-A7.output > t0
sort test-A7a.reqd > t1
sort test-A7b.reqd > t2
sort test-A7c.reqd > t3

diff -w t0 t1 > v1
diff -w t0 t2 > v2
diff -w t0 t3 > v3

if(-z v1 || -z v2 || -z v3) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 v1 t2 t3 v2 v3 test-A7.output 
