#!/bin/csh

echo "Test B2 for mat2harbo.pl"
echo "Running mat2harbo.pl test-B2.mat"

mat2harbo.pl test-B2.mat >& test-B2.output

sort test-B2.output > t0
sort test-B2.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B2.output
 
