#!/bin/csh

echo "Test B1 for order2vec.pl"
echo "Running order2vec.pl --dense test-B1.sval2 test-B1.wordvec test-B1.regex"

order2vec.pl --dense test-B1.sval2 test-B1.wordvec test-B1.regex >& test-B1.output

sort test-B1.output > t0
sort test-B1.reqd > t1

diff -w t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B1.output 
 
