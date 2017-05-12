#!/bin/csh

echo "Test B1 for mat2harbo.pl"
echo "Running mat2harbo.pl --cpform 10f8.3 test-B1.mat"

mat2harbo.pl --cpform 10f8.3 test-B1.mat >& test-B11.output

sort test-B11.output > t0
sort test-B11.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B11.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B11.output 
#/bin/rm -f matrix*.mat2harbo line1*.mat2harbo 
 
echo "Running mat2harbo.pl --rpform 10f8 test-B1.mat"

mat2harbo.pl --rpform 10f8 test-B1.mat >& test-B12.output

sort test-B12.output > t0
sort test-B12.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B12.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B12.output
#/bin/rm -f matrix*.mat2harbo line1*.mat2harbo 

echo "Running mat2harbo.pl --numform 10i8.3 test-B1.mat"

mat2harbo.pl --numform 10i8.3 test-B1.mat >& test-B13.output

sort test-B13.output > t0
sort test-B13.reqd > t1

diff -w t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B13.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B13.output

