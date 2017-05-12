#!/bin/csh

echo "Test A2 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 20i4 test-A2.mat"

mat2harbo.pl --numform 20i4 test-A2.mat > test-A2.output

diff test-A2.output test-A2.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f var test-A2.output 
 
