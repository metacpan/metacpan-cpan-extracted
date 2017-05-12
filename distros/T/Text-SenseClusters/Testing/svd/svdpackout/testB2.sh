#!/bin/csh

echo "Test B2 for svdpackout.pl"

echo "Running svdpackout.pl test-B2.lav2 test-B2.lao2"

svdpackout.pl test-B2.lao2 test-B2.lav2 >& test-B2.output

sort test-B2.output > t0
sort test-B2.reqd > t1

diff t0 t1 >& var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B2.output 
 
