#!/bin/csh

echo "Test A5 for order2vec.pl"
echo "Running order2vec.pl --dense --format i2 test-A5.sval2 test-A51.wordvec test-A5.regex"

order2vec.pl --dense --format i2 test-A5.sval2 test-A51.wordvec test-A5.regex > test-A5.output

diff -w test-A51.reqd test-A5.output > var1
diff -w test-A5.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A51.reqd";
	cat var1;
	echo "When tested against test-A5.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A5.output keyfile*.key 
 
echo "Running order2vec.pl --format i2 test-A5.sval2 test-A52.wordvec test-A5.regex"

order2vec.pl --format i2 test-A5.sval2 test-A52.wordvec test-A5.regex > test-A5.output

diff -w test-A52.reqd test-A5.output > var1
diff -w test-A5.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A52.reqd";
        cat var1;
        echo "When tested against test-A5.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A5.output keyfile*.key
