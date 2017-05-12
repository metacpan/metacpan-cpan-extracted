#!/bin/csh

echo "Test A2 for combig.pl"
echo "Running combig.pl test-A2.big"

combig.pl test-A2.big > test-A2.output

sort test-A2.output > t0
sort test-A2.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-A2.output
 
