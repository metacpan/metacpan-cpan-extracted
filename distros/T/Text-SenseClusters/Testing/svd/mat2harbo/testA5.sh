#!/bin/csh

echo "Test A5 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 5f16.8 test-A5.mat"

mat2harbo.pl --numform 5f16.8 test-A5.mat > test-A5.output

diff test-A5.output test-A5.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A5.reqd";
	cat var;
endif

/bin/rm -f var test-A5.output 
 
