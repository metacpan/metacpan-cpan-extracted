#!/bin/csh
echo "Test B1 - Testing an error condition when some instances are attached tags";
echo "in untagged data";
echo "Running prepare_sval2.pl test-B1.data";
prepare_sval2.pl test-B1.data >& test-B1.output
sort test-B1.output > t0
sort test-B1.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test B1 OK";
else
	echo "Test B1 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-B1.output 
/bin/rm -f temp*.prepare_sval2 
