#!/bin/csh

echo "Test B2 for text2sval.pl"
echo "Running text2sval.pl --key test-B2.key --lexelt line-n test-B2.text"

text2sval.pl --key test-B2.key --lexelt line-n test-B2.text >& test-B2.output

diff -w test-B2.output test-B2.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat var;
endif

/bin/rm -f var test-B2.output tempfile*.text2sval 
