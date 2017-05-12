#!/bin/csh

echo "Test B5 for order2vec.pl"
echo "Running order2vec.pl test-B5.sval2 test-B5.wordvec test-B5.regex"

order2vec.pl test-B5.sval2 test-B5.wordvec test-B5.regex >& test-B5.output

diff -w test-B5.reqd test-B5.output > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B5.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B5.output 
 
