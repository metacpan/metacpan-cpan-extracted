#!/bin/csh

echo "Test A2 for svdpackout.pl"

cp test-A2.matrix matrix
cp test-A2.lap2 lap2

echo "Running las2"
las2

echo "Running svdpackout.pl --format f8.3 lav2 lao2 > test-A2.output"
svdpackout.pl --format f8.3 lav2 lao2 > test-A2.output

sort test-A2.output > t0
sort test-A2.reqd > t1

diff t0 t1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A2.output

