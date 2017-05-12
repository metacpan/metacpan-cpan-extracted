#!/bin/csh

echo "Test B2 for wordvec.pl"
echo "Running wordvec.pl --wordorder nocare test-B2.bi"

wordvec.pl --wordorder nocare test-B2.bi >& test-B2.output

sort test-B2.output > t0
sort test-B2.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B2.output 

echo "Running wordvec.pl --wordorder nocare --feats test-B2.feats test-B2.bi"

wordvec.pl --wordorder nocare --feats test-B2.feats test-B2.bi >& test-B2.output

sort test-B2.output > t0
sort test-B2.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B2.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B2.output
