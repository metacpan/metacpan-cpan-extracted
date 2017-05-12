#!/bin/csh
echo "Test A8 for bitsimat.pl"
echo "Running bitsimat.pl --dense --format f6.3 test-A81.vec"

bitsimat.pl --dense --format f6.3 test-A81.vec > test-A81.output

diff test-A81.output test-A81.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A81.reqd";
        cat var;
endif

/bin/rm -f var test-A81.output

echo "Running bitsimat.pl --format f6.3 test-A82.vec"

bitsimat.pl --format f6.3 test-A82.vec > test-A82.output

diff -w test-A82.output test-A82.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A82.reqd";
        cat var;
endif

/bin/rm -f var test-A82.output
