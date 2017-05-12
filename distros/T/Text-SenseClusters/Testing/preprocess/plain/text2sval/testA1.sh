#!/bin/csh

echo "Test A1 for text2sval.pl"
echo "Running text2sval.pl --key test-A1.key --lexelt line-n test-A1.text"

text2sval.pl --key test-A1.key --lexelt line-n test-A1.text > test-A1.output

diff -w test-A1.output test-A1.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f var test-A1.output 
 
