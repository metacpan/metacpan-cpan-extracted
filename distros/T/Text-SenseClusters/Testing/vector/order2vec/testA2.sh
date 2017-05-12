#!/bin/csh

echo "Test A2 for order2vec.pl"
echo "Running order2vec.pl --dense --format f7.3 test-A2.sval2 test-A21.wordvec test-A2.regex"

order2vec.pl --dense --format f7.3 test-A2.sval2 test-A21.wordvec test-A2.regex > test-A2.output

diff -w test-A2.output test-A21.reqd > var1
diff -w test-A2.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A21.reqd";
	cat var1;
	echo "When tested against test-A2.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A2.output keyfile*.key 
 
echo "Running order2vec.pl --format f7.3 test-A2.sval2 test-A22.wordvec test-A2.regex"

order2vec.pl --format f7.3 test-A2.sval2 test-A22.wordvec test-A2.regex > test-A2.output

diff -w test-A2.output test-A22.reqd > var1
diff -w test-A2.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A22.reqd";
        cat var1;
        echo "When tested against test-A2.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A2.output keyfile*.key

