#!/bin/csh
echo "Test B2 for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure cosine --format f8.4 test-B21.vec"

bitsimat.pl --dense --measure cosine --format f8.4 test-B21.vec >& test-B21.output

sort test-B21.output > t0
sort test-B21.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B21.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B21.output

echo "Running bitsimat.pl --measure cosine --format f8.4 test-B22.vec"

bitsimat.pl --measure cosine --format f8.4 test-B22.vec >& test-B22.output

sort test-B22.output > t0
sort test-B22.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B22.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B22.output
