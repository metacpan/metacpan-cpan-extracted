#!/bin/csh
echo "Test A4 - Testing if prepare_sval2 attaches tags from KEY file.";
echo "Running prepare_sval2.pl --key test-A4.key test-A4.data";
prepare_sval2.pl --key test-A4.key test-A4.data > test-A4.output
sort test-A4.output > t0
sort test-A4.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A4 OK";
else
	echo "Test A4 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A4.output
