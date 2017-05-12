#!/bin/csh

echo "Test A10 for simat.pl"
echo "Running simat.pl --format f6.3 --dense test-A10a.vec"

simat.pl --format f6.3 --dense test-A10a.vec > test-A10a.output

diff -w test-A10a.output test-A10a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A10a.reqd";
	cat var;
endif

/bin/rm -f var test-A10a.output 

echo "Running simat.pl --format f6.3 test-A10b.vec"

simat.pl --format f6.3 test-A10b.vec > test-A10b.output

diff -w test-A10b.output test-A10b.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10b.reqd";
        cat var;
endif

/bin/rm -f var test-A10b.output
