#!/bin/csh

echo "Test A3 for combig.pl"
echo "Running combig.pl test-A3.big"

combig.pl test-A3.big > test-A3.output

sort test-A3.output > t0
sort test-A3.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-A3.output 
 
