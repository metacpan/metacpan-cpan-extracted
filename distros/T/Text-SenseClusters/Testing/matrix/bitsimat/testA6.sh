#!/bin/csh
echo "Test A6 for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure cosine --format f8.4 test-A61.vec"

bitsimat.pl --dense --measure cosine --format f8.4 test-A61.vec > test-A61.output

diff test-A61.output test-A61.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A61.reqd";
        cat var;
endif

/bin/rm -f var test-A61.output

echo "Running bitsimat.pl --measure cosine --format f8.4 test-A62.vec"

bitsimat.pl --measure cosine --format f8.4 test-A62.vec > test-A62.output

diff -w test-A62.output test-A62.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A62.reqd";
        cat var;
endif

/bin/rm -f var test-A62.output
