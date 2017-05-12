#!/bin/csh

echo "Test B3 for text2sval.pl"
echo "Running text2sval.pl --key test-B3.key --lexelt line-n test-B3.text"

text2sval.pl --key test-B3.key --lexelt line-n test-B3.text >& test-B3.output

diff -w test-B3.output test-B3.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B3.reqd";
	cat var;
endif

/bin/rm -f var test-B3.output 
