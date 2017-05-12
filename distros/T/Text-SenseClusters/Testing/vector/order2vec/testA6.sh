#!/bin/csh

echo "Test A6 for order2vec.pl"
echo "Running order2vec.pl --dense --format f8.4 test-A6.sval2 test-A61.wordvec test-A6.regex"

order2vec.pl --dense --format f8.4 test-A6.sval2 test-A61.wordvec test-A6.regex > test-A6.output

diff -w test-A61.reqd test-A6.output > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A61.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A6.output keyfile*.key
 
echo "Running order2vec.pl --format f8.4 test-A6.sval2 test-A62.wordvec test-A6.regex"

order2vec.pl --format f8.4 test-A6.sval2 test-A62.wordvec test-A6.regex > test-A6.output

diff -w test-A62.reqd test-A6.output > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A62.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A6.output keyfile*.key
