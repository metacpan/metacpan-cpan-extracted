#!/bin/csh

echo "Test A4 for combig.pl"
echo "Running combig.pl test-A4.big"

combig.pl test-A4.big > test-A4.output

sort test-A4.output > t0
sort test-A4.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4.reqd";
	cat var1;
endif

/bin/rm -f var1 t0 t1 test-A4.output 
 
