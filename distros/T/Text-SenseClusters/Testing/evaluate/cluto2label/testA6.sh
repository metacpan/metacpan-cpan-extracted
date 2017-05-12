#!/bin/csh
echo "Test A6 Testing cluto2label.pl"
echo "Running cluto2label.pl --numthrow 2 test-A6.cluto test-A6.key"
cluto2label.pl --numthrow 2 test-A6.cluto test-A6.key > test-A6.output
sort test-A6.reqd > t0
sort test-A6.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A6 OK"
else
	echo "Test A6 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A6.output

