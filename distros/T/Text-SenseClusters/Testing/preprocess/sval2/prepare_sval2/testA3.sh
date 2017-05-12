#!/bin/csh
echo "Test A3 - Testing if prepare_sval2 attaches NOTAGs when Input is untagged.";
echo "Running prepare_sval2.pl test-A3.data";
prepare_sval2.pl test-A3.data > test-A3.output
sort test-A3.output > t0
sort test-A3.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A3 OK";
else
	echo "Test A3 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A3.output
