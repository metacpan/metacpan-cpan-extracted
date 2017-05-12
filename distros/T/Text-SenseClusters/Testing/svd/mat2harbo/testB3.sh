#!/bin/csh

echo "Test B3 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 8f10.6 test-B31.mat"

mat2harbo.pl --numform 8f10.6 test-B31.mat >& test-B31.output

grep "Value <147.430000> can't be represented with format %10.6f." test-B31.output > t0

if(-z t0) then
	echo "Test Error";
	echo "When tested against test-B31.reqd";
else
	echo "Test Ok";
endif

/bin/rm -f t0 test-B31.output blk*.mat2harbo
 
echo "Running mat2harbo.pl --cpform 16i5 test-B32.mat"

mat2harbo.pl --cpform 16i5 test-B32.mat >& test-B32.output

grep "Column pointer <10011> can't be represented with format %5d." test-B32.output > t0

if(-z t0) then
	echo "Test Error";
	echo "When tested against test-B32.reqd";
else
	echo "Test Ok";
endif

/bin/rm -f t0 test-B32.output blk*.mat2harbo

echo "Running mat2harbo.pl --rpform 20i4 test-B32.mat"

mat2harbo.pl --rpform 20i4 test-B32.mat >& test-B33.output

grep "Row pointer <1286> can't be represented with format %4d." test-B33.output > t0

if(-z t0) then
	echo "Test Error";
	echo "When tested against test-B33.reqd";
else
	echo "Test Ok";
endif

/bin/rm -f t0 test-B33.output blk*.mat2harbo

echo "Running mat2harbo.pl --numform 10f8.3 --cpform 20i4 --rpform 40i2 test-B34.mat"

mat2harbo.pl --numform 10f8.3 --cpform 20i4 --rpform 40i2 test-B34.mat >& test-B34.output

grep "Value <-132.864> can't be represented with format %8.3f." test-B34.output > t0

if(-z t0) then
	echo "Test Error";
	echo "When tested against test-B34.reqd";
else
	echo "Test Ok";
endif

/bin/rm -f t0 test-B34.output blk*.mat2harbo
