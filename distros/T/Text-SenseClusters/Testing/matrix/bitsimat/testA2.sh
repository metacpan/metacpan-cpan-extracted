#!/bin/csh
echo "Test A2 for bitsimat.pl"
echo "Running bitsimat.pl --dense --format i2 --measure match test-A21.vec"

bitsimat.pl --dense --format i2 --measure match test-A21.vec > test-A21.output

diff test-A21.output test-A21.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A21.reqd";
        cat var;
endif

/bin/rm -f var test-A21.output

echo "Running bitsimat.pl --format i2 --measure match test-A22.vec"

bitsimat.pl --format i2 --measure match test-A22.vec > test-A22.output

diff -w test-A22.output test-A22.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A22.reqd";
        cat var;
endif

/bin/rm -f var test-A22.output

