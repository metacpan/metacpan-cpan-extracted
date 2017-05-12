#!/bin/csh
echo "Test A4 for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure overlap --format f8.3 test-A41.vec"

bitsimat.pl --dense --measure overlap --format f8.3 test-A41.vec > test-A41.output

diff test-A41.output test-A41.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A41.reqd";
        cat var;
endif

/bin/rm -f var test-A41.output

echo "Running bitsimat.pl --measure overlap --format f8.3 test-A42.vec"

bitsimat.pl --measure overlap --format f8.3 test-A42.vec > test-A42.output

diff -w test-A42.output test-A42.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A42.reqd";
        cat var;
endif

/bin/rm -f var test-A42.output
