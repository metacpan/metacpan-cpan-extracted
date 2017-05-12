#!/bin/csh
echo "Test A7 Testing cluto2label.pl"
echo "Running cluto2label.pl --perthrow 10 test-A7.cluto test-A7.key"
cluto2label.pl --perthrow 10 test-A7.cluto test-A7.key > test-A7.output
sort test-A7.reqd > t0
sort test-A7.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A7 OK"
else
	echo "Test A7 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A7.output

