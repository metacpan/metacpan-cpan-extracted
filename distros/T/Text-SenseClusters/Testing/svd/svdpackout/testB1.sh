#!/bin/csh

echo "Test B1 for svdpackout.pl"

echo "Running svdpackout.pl test-B1.lav2 test-B1.lao2"

svdpackout.pl test-B1.lav2 test-B1.lao2 >& test-B1.output

sort test-B1.output > t0
sort test-B1.reqd > t1

diff t0 t1 >& var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B1.output 
 
