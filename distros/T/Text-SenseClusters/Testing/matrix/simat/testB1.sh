#!/bin/csh

echo "Test B1 for simat.pl"
echo "Running simat.pl --dense --format f7.3 test-B1a.vec"

simat.pl --dense --format f7.3 test-B1a.vec >& test-B1a.output

# no needed for errornous cases - create problem.
#sort test-B1a.output > t0
#sort test-B1a.reqd > t1

diff -w test-B1a.output test-B1a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B1a.output 
 
echo "Running simat.pl --format f7.3 test-B1b.vec"

simat.pl --format f7.3 test-B1b.vec >& test-B1b.output

#sort test-B1b.output > t0
#sort test-B1b.reqd > t1

diff -w test-B1b.output test-B1b.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B1b.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B1b.output
