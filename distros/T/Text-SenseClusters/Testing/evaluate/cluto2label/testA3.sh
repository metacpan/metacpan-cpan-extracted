#!/bin/csh
echo "Test A3 Testing cluto2label.pl"
echo "Running cluto2label.pl test-A3.cluto test-A3.key"
cluto2label.pl test-A3.cluto test-A3.key > test-A3.output
sort test-A3.reqd > t0
sort test-A3.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A3 OK"
else
	echo "Test A3 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A3.output

