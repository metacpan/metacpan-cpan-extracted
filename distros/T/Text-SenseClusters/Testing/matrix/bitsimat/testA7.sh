#!/bin/csh
echo "Test A7 for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure cosine --format f8.4 test-A71.vec"

bitsimat.pl --dense --measure cosine --format f8.4 test-A71.vec > test-A71.output

diff test-A71.output test-A71.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A71.reqd";
        cat var;
endif

/bin/rm -f var test-A71.output

echo "Running bitsimat.pl --measure cosine --format f8.4 test-A72.vec"

bitsimat.pl --measure cosine --format f8.4 test-A72.vec > test-A72.output

diff -w test-A72.output test-A72.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A72.reqd";
        cat var;
endif

/bin/rm -f var test-A72.output
