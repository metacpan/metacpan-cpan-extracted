#!/bin/csh

echo "Test A5 for svdpackout.pl"

cp test-A5.matrix matrix
cp test-A5.lap2 lap2

echo "Running las2"
las2

echo "Running svdpackout.pl --rowonly --format f9.5 lav2 lao2 > test-A5.output"
svdpackout.pl --rowonly --format f9.5 lav2 lao2 > test-A5.output

sort test-A5.output > t0
sort test-A5.reqd > t1

diff t0 t1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A5.output

