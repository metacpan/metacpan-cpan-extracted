#!/bin/csh
echo "Test A2 Testing cluto2label.pl"
echo "Running cluto2label.pl test-A2.cluto test-A2.key"
cluto2label.pl test-A2.cluto test-A2.key > test-A2.output
sort test-A2.reqd > t0
sort test-A2.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A2 OK"
else
	echo "Test A2 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A2.output

