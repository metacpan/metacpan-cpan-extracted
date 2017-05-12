#!/bin/csh
echo "Test A4 - Testing frequency.pl when Source is a part of actual Senseval-2.";
echo "Running frequency.pl test-A4.source";
frequency.pl test-A4.source > test-A4.output
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
