#!/bin/csh

echo "Test B2 for simat.pl"
echo "Running simat.pl --dense --format f7.4 test-B2a.vec"

simat.pl --dense --format f7.4 test-B2a.vec >& test-B2a.output

#sort test-B2a.output > t0
#sort test-B2a.reqd > t1

diff -w test-B2a.output test-B2a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B2a.output matrix*.simat* cosine*.simat* 
 
echo "Running simat.pl --format f7.4 test-B2b.vec"

simat.pl --format f7.4 test-B2b.vec >& test-B2b.output

#sort test-B2b.output > t0
#sort test-B2b.reqd > t1

diff -w test-B2b.output test-B2b.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B2b.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B2b.output
