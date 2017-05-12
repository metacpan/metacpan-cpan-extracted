#!/bin/csh

echo "Test A3 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 10f8.3 test-A3.mat"

mat2harbo.pl --numform 10f8.3 test-A3.mat > test-A3.output

diff test-A3.output test-A3.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var;
endif

/bin/rm -f var test-A3.output 
 
