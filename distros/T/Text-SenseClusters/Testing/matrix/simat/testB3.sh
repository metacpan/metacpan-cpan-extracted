#!/bin/csh

echo "Test B3 for simat.pl"
echo "Running simat.pl --dense --format f7.4 test-B3a.vec"

simat.pl --dense --format f7.4 test-B3a.vec >& test-B3a.output

#sort test-B3a.output > t0
#sort test-B3a.reqd > t1

diff -w test-B3a.output test-B3a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B3a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B3a.output matrix*.simat* cosine*.simat* 

echo "Running simat.pl --format f7.4 test-B3b.vec"

simat.pl --format f7.4 test-B3b.vec >& test-B3b.output

#sort test-B3b.output > t0
#sort test-B3b.reqd > t1

diff -w test-B3b.output test-B3b.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B3b.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B3b.output
