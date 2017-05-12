#!/bin/csh
echo "Test A8  for balance.pl";
echo "Running balance.pl --count test-A8.count test-A8.xml 2";
balance.pl --count test-A8.count test-A8.xml 2 > test-A8.output
sort test-A8.output > t0
sort test-A8a.reqd > t1
sort test-A8b.reqd > t2
sort test-A8c.reqd > t3
sort test-A8.count.balanced > c0
sort test-A8a.count.reqd > c1
sort test-A8b.count.reqd > c2
sort test-A8c.count.reqd > c3

diff -w t0 t1 > v1
diff -w t0 t2 > v2
diff -w t0 t3 > v3

diff -w c0 c1 > vc1
diff -w c0 c2 > vc2
diff -w c0 c3 > vc3

if((-z v1 && -z vc1) || (-z v2 && -z vc2) || (-z v3 && -z vc3)) then
	echo "Test Ok";
else
	echo "Test Error";
endif
/bin/rm t0 t1 v1 t2 t3 v2 v3 c0 c1 c2 c3 vc1 vc2 vc3 test-A8.count.balanced test-A8.output 
