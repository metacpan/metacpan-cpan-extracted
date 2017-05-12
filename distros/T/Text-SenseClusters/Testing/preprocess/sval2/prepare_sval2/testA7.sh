#!/bin/csh
echo "Test A7 - Testing some instances are not tagged.";
echo "Running prepare_sval2.pl test-A7.data";
prepare_sval2.pl test-A7.data > test-A7.output
sort test-A7.output > t0
sort test-A7.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A7 OK";
else
	echo "Test A7 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A7.output
