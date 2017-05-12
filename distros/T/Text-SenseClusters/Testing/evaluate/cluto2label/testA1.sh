#!/bin/csh
echo "Test A1 Testing cluto2label.pl"
echo "Running cluto2label.pl test-A1.cluto test-A1.key"
cluto2label.pl test-A1.cluto test-A1.key > test-A1.output
sort -b test-A1.reqd > t0
sort -b test-A1.output > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A1 OK"
else
	echo "Test A1 ERROR"
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A1.output

