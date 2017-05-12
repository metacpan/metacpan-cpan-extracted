#!/bin/csh

echo "Test A3 for text2sval.pl"
echo "Running text2sval.pl --key test-A3.key --lexelt line-n test-A3.text"

text2sval.pl --key test-A3.key --lexelt line-n test-A3.text > test-A3.output

diff -w test-A3.output test-A3.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var;
endif

/bin/rm -f var test-A3.output 
 
