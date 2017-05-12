#!/bin/csh

echo "Test A6 for combig.pl"
echo "Running combig.pl test-A6.big"

combig.pl test-A6.big > test-A6.output

sort test-A6.output > t0
sort test-A6.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A6.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-A6.output 
 
