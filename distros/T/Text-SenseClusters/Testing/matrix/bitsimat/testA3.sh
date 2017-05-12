#!/bin/csh
echo "Test A3 for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure dice --format f8.3 test-A31.vec"

bitsimat.pl --dense --measure dice --format f8.3 test-A31.vec > test-A31.output

diff test-A31.output test-A31.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A31.reqd";
        cat var;
endif

/bin/rm -f var test-A31.output

echo "Running bitsimat.pl --measure dice --format f8.3 test-A32.vec"

bitsimat.pl --measure dice --format f8.3 test-A32.vec > test-A32.output

diff -w test-A32.output test-A32.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A32.reqd";
        cat var;
endif

/bin/rm -f var test-A32.output

