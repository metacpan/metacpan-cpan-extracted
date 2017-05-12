#!/bin/csh

echo "Test B3 for order2vec.pl"
echo "Running order2vec.pl test-B3.sval2 test-B3.wordvec test-B3.regex"

order2vec.pl test-B3.sval2 test-B3.wordvec test-B3.regex >& test-B3.output

diff -w test-B3.reqd test-B3.output > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B3.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B3.output 
 
