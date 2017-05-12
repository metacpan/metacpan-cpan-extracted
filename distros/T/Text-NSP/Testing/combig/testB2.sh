#!/bin/csh

echo "Test B2 for combig.pl"
echo "Running combig.pl test-B2.big"

combig.pl test-B2.big >& test-B2.output

sort test-B2.output > t0
sort test-B2.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-B2.output 
 
