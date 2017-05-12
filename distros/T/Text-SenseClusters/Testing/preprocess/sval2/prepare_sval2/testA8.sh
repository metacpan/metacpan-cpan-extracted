#!/bin/csh
echo "Test A8 - Testing when instances are tagged with single tag=P.";
echo "Running prepare_sval2.pl test-A8.data";
prepare_sval2.pl test-A8.data > test-A8.output
sort test-A8.output > t0
sort test-A8.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A8 OK";
else
	echo "Test A8 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A8.output
