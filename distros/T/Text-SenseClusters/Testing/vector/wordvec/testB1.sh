#!/bin/csh

echo "Test B1 for wordvec.pl"
echo "Running wordvec.pl --dense --format i4 test-B1a.bi"

wordvec.pl --dense --format i4 test-B1a.bi >& test-B1a.output

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

echo "Running wordvec.pl --dense --format f20.10 test-B1b.bi"

wordvec.pl --dense --format f20.10 test-B1b.bi >& test-B1b.output

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

echo "Running wordvec.pl --dense --format f20.10 test-B1c.bi"

wordvec.pl --dense --format f20.10 test-B1c.bi >& test-B1c.output

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
