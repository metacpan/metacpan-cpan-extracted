#!/bin/csh

echo "Test A1 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 20i4 test-A1.mat"

mat2harbo.pl --numform 20i4 test-A1.mat > test-A1.output

diff test-A1.output test-A1.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f var test-A1.output 
 
