#!/bin/csh

echo "Test A1a for bitsimat.pl"
echo "Running bitsimat.pl --dense --format f8.3 test-A1a1.vec"

bitsimat.pl --dense --format f8.3 test-A1a1.vec > test-A1a1.output

sort test-A1a1.output > t0
sort test-A1a1.reqd > t1

diff t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1a1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-A1a1.output 

echo "Running bitsimat.pl --format f8.3 test-A1a2.vec"

bitsimat.pl --format f8.3 test-A1a2.vec > test-A1a2.output

diff -w test-A1a2.output test-A1a2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1a2.reqd";
        cat var;
endif

/bin/rm -f var test-A1a2.output
 

echo "Test A1b for bitsimat.pl"
echo "Running bitsimat.pl --dense --format f8.3 test-A1b1.vec"

bitsimat.pl --dense --format f8.3 test-A1b1.vec > test-A1b1.output

sort test-A1b1.output > t0
sort test-A1b1.reqd > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1b1.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-A1b1.output

echo "Running bitsimat.pl --format f8.3 test-A1b2.vec"

bitsimat.pl --format f8.3 test-A1b2.vec > test-A1b2.output

diff -w test-A1b2.output test-A1b2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1b2.reqd";
        cat var;
endif

/bin/rm -f var test-A1b2.output


echo "Test A1c for bitsimat.pl"
echo "Running bitsimat.pl --dense --format f8.3 test-A1c1.vec"

bitsimat.pl --dense --format f8.3 test-A1c1.vec > test-A1c1.output

diff test-A1c1.output test-A1c1.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1c1.reqd";
        cat var;
endif

/bin/rm -f var test-A1c1.output

echo "Running bitsimat.pl --format f8.3 test-A1c2.vec"

bitsimat.pl --format f8.3 test-A1c2.vec > test-A1c2.output

diff -w test-A1c2.output test-A1c2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1c2.reqd";
        cat var;
endif

/bin/rm -f var test-A1c2.output

