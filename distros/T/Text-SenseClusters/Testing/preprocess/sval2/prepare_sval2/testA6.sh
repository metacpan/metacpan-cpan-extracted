#!/bin/csh
echo "Test A6 - Testing when KEY file has tags for already tagged data.";
echo "Running prepare_sval2.pl --key test-A6.key test-A6.data";
prepare_sval2.pl --key test-A6.key test-A6.data > test-A6.output
sort test-A6.output > t0
sort test-A6.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A6 OK";
else
	echo "Test A6 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A6.output
