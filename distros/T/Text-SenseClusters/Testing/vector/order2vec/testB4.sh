#!/bin/csh

echo "Test B4 for order2vec.pl"
echo "Running order2vec.pl test-B4.sval2 test-B4.wordvec test-B4.regex"

order2vec.pl test-B4.sval2 test-B4.wordvec test-B4.regex >& test-B4.output

diff -w test-B4.reqd test-B4.output > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B4.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B4.output 
 
