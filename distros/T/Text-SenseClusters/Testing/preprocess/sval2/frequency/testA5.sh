#!/bin/csh
echo "Test A5 - Testing frequency.pl when Source is a part of actual Senseval-2.";
echo "And single sense tag occurs.";
echo "Running frequency.pl test-A5.source";
frequency.pl test-A5.source > test-A5.output
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
