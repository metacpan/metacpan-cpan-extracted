#!/bin/csh
echo "Test A5 for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure jaccard --format f8.3 test-A51.vec"

bitsimat.pl --dense --measure jaccard --format f8.3 test-A51.vec > test-A51.output

diff test-A51.output test-A51.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A51.reqd";
        cat var;
endif

/bin/rm -f var test-A51.output

echo "Running bitsimat.pl --measure jaccard --format f8.3 test-A52.vec"

bitsimat.pl --measure jaccard --format f8.3 test-A52.vec > test-A52.output

diff -w test-A52.output test-A52.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A52.reqd";
        cat var;
endif

/bin/rm -f var test-A52.output
