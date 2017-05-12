#!/bin/csh

echo "Test A4 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 40i2 test-A4.mat"

mat2harbo.pl --numform 40i2 test-A4.mat > test-A4.output

diff test-A4.output test-A4.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4.reqd";
	cat var;
endif

/bin/rm -f var test-A4.output 
 
