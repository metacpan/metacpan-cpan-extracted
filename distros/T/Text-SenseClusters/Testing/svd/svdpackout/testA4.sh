#!/bin/csh

echo "Test A4 for svdpackout.pl"

cp test-A4.matrix matrix
cp test-A4.lap2 lap2

echo "Running las2"
las2

echo "Running svdpackout.pl --format f8.3 lav2 lao2 > test-A4.output"
svdpackout.pl --format f8.3 lav2 lao2 > test-A4.output

sort test-A4.output > t0
sort test-A4.reqd > t1

diff t0 t1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A4.output

