#!/bin/csh

echo "Test A11 for mat2harbo.pl"
echo "Running mat2harbo.pl --param --numform 8f10.6 --iter 8 --k 5 --rf 3 test-A11.mat"

mat2harbo.pl --param --numform 8f10.6 --iter 8 --k 5 --rf 3 test-A11.mat > test-A11.output

diff test-A11.output test-A11.reqd > var

diff lap2 test-A11.lap2.reqd > var1

if(-z var && -z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A11.reqd";
	cat var;
	echo "When tested against test-A11.lap2.reqd";
        cat var1;
endif

/bin/rm -f var lap2 var1 test-A11.output
 
