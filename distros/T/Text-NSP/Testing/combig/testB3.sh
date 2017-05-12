#!/bin/csh

echo "Test B3 for combig.pl"
echo "Running combig.pl test-B3.big"

combig.pl test-B3.big >& test-B3.output

sort test-B3.output > t0
sort test-B3.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B3.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-B3.output 
 
