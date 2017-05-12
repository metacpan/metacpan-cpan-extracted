#!/bin/csh
echo "Test A4 Testing cluto2label.pl"
echo "Running cluto2label.pl test-A4.cluto test-A4.key"
cluto2label.pl test-A4.cluto test-A4.key > test-A4.output
sort test-A4.reqd > t0
sort test-A4.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A4 OK"
else
	echo "Test A4 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A4.output

