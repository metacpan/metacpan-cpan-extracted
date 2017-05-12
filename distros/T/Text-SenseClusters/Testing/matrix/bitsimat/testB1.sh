#!/bin/csh
echo "Test B1a for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure cosine --format f8.4 test-B1a.vec"

bitsimat.pl --dense --measure cosine --format f8.4 test-B1a.vec >& test-B1a.output

sort test-B1a.output > t0
sort test-B1a.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B1a.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B1a.output

echo "Test B1b for bitsimat.pl"
echo "Running bitsimat.pl --dense --measure cosine --format f8.4 test-B1b.vec"

bitsimat.pl --dense --measure cosine --format f8.4 test-B1b.vec >& test-B1b.output

sort test-B1b.output > t0
sort test-B1b.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B1b.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B1b.output

echo "Running bitsimat.pl --measure cosine --format f8.4 test-B1c.vec"

bitsimat.pl --measure cosine --format f8.4 test-B1c.vec >& test-B1c.output

sort test-B1c.output > t0
sort test-B1c.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B1c.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B1c.output
