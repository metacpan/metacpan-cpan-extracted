#!/bin/csh
echo "Test A5 - Testing when some instances do not have tags in KEY file.";
echo "Running prepare_sval2.pl --key test-A5.key test-A5.data";
prepare_sval2.pl --key test-A5.key test-A5.data > test-A5.output
sort test-A5.output > t0
sort test-A5.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A5 OK";
else
	echo "Test A5 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A5.output
