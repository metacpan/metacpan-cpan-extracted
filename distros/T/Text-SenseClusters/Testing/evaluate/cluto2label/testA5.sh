#!/bin/csh
echo "Test A5 Testing cluto2label.pl"
echo "Running cluto2label.pl test-A5.cluto test-A5.key"
cluto2label.pl test-A5.cluto test-A5.key > test-A5.output
sort test-A5.reqd > t0
sort test-A5.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A5 OK"
else
	echo "Test A5 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A5.output

