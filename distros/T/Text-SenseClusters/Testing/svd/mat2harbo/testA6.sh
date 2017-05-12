#!/bin/csh

echo "Test A6 for mat2harbo.pl"
echo "Running mat2harbo.pl --title linedata --id bigraph --cpform 8i10 --rpform 8i10 --numform 8f10.5 test-A6.mat"

mat2harbo.pl --title linedata --id bigraph --cpform 8i10 --rpform 8i10 --numform 8f10.5 test-A6.mat > test-A6.output

diff test-A6.output test-A6.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A6.reqd";
	cat var;
endif

/bin/rm -f var test-A6.output 
 
