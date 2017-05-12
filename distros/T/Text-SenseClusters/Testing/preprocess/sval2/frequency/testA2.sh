#!/bin/csh
echo "Test A2 - Testing frequency.pl when Source has only one sense(100%).";
echo "Running frequency.pl test-A2.source";
frequency.pl test-A2.source > test-A2.output
sort test-A2.output > t0
sort test-A2.reqd > t1
diff -w t0 t1 > v1
if(-z v1) then
	echo "Test A2 OK";
else
	echo "Test A2 ERROR";
	cat v1
endif
/bin/rm -f t0 t1 v1 test-A2.output
