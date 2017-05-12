#!/bin/csh
echo "Test A1 - Testing frequency.pl when Source has balanced distribution.";
echo "Running frequency.pl test-A1.source";
frequency.pl test-A1.source > test-A1.output
sort test-A1.output > t0
sort test-A1.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A1 OK";
else
	echo "Test A1 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A1.output
