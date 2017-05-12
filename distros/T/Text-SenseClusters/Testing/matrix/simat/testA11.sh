#!/bin/csh

echo "Test A11 for simat.pl"
echo "Running simat.pl --format f6.3 --dense test-A11a.vec"

simat.pl --format f6.3 --dense test-A11a.vec > test-A11a.output

diff -w test-A11a.output test-A11a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A11a.reqd";
	cat var;
endif

/bin/rm -f var test-A11a.output 

echo "Running simat.pl --format f6.3 test-A11b.vec"

simat.pl --format f6.3 test-A11b.vec > test-A11b.output

diff -w test-A11b.output test-A11b.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A11b.reqd";
        cat var;
endif

/bin/rm -f var test-A11b.output
