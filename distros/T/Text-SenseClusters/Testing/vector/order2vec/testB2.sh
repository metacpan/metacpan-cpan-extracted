#!/bin/csh

echo "Test B2 for order2vec.pl"
echo "Running order2vec.pl --dense --format i2 test-B2.sval2 test-B21.wordvec test-B2.regex"

order2vec.pl --dense --format i2 test-B2.sval2 test-B21.wordvec test-B2.regex >& test-B2.output

diff -w test-B21.reqd test-B2.output > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B21.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 test-B2.output 
 
echo "Running order2vec.pl test-B2.sval2 test-B22.wordvec test-B2.regex"

order2vec.pl test-B2.sval2 test-B22.wordvec test-B2.regex >& test-B2.output

diff -w test-B22.reqd test-B2.output > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-B22.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 test-B2.output
