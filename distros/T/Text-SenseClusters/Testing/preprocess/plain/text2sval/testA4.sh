#!/bin/csh

echo "Test A4 for text2sval.pl"
echo "Running text2sval.pl --key test-A4.key --lexelt serve-v test-A4.text"

text2sval.pl --key test-A4.key --lexelt serve-v test-A4.text > test-A4.output

diff -w test-A4.output test-A4.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4.reqd";
	cat var;
endif

/bin/rm -f var test-A4.output 
 
