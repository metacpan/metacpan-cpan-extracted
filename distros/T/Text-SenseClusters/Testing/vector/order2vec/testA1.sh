#!/bin/csh

echo "Test A1 for order2vec.pl"
echo "Running order2vec.pl --dense --format f6.3 test-A1.sval2 test-A11.wordvec test-A1.regex"

order2vec.pl --dense --format f6.3 test-A1.sval2 test-A11.wordvec test-A1.regex > test-A1.output

diff -w test-A1.output test-A11.reqd > var1

diff -w test-A1.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A11.reqd";
	cat var1;
	echo "When tested against test-A1.key";
        cat var2;
endif

/bin/rm -f var var1 var2 test-A1.output keyfile*.key 
 
echo "Running order2vec.pl --format f6.3 test-A1.sval2 test-A12.wordvec test-A1.regex"

order2vec.pl --format f6.3 test-A1.sval2 test-A12.wordvec test-A1.regex > test-A1.output

diff -w test-A1.output test-A12.reqd > var1

diff -w test-A1.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A12.reqd";
        cat var1;
        echo "When tested against test-A1.key";
        cat var2;
endif

/bin/rm -f var var1 var2 test-A1.output keyfile*.key
