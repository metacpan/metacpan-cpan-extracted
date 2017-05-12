#!/bin/csh

echo "Test B1 for text2sval.pl"
echo "Running text2sval.pl --key test-B1.key --lexelt line-n test-B1.text"

text2sval.pl --key test-B1.key --lexelt line-n test-B1.text >& test-B1.output

diff -w test-B1.output test-B1.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f var test-B1.output tempfile*.text2sval 
