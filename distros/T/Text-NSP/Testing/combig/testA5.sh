#!/bin/csh

echo "Test A5 for combig.pl"
echo "Running combig.pl test-A5.big"

combig.pl test-A5.big > test-A5.output

sort test-A5.output > t0
sort test-A5.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A5.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-A5.output 
 
