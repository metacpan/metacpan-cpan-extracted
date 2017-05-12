#!/bin/csh

echo "Test A2 for text2sval.pl"
echo "Running text2sval.pl test-A2.text"

text2sval.pl test-A2.text > test-A2.output

diff -w test-A2.output test-A2.reqd  > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f var test-A2.output 
 
