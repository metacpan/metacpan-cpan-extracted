#!/bin/csh

echo "Test A4 for order2vec.pl"
echo "Running order2vec.pl --dense --format f6.3 test-A4.sval2 test-A41.wordvec test-A4.regex"

order2vec.pl --dense --format f6.3 test-A4.sval2 test-A41.wordvec test-A4.regex > test-A4.output

diff -w test-A4.output test-A41.reqd > var1
diff -w test-A4.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A41.reqd";
	cat var1;
	echo "When tested against test-A4.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A4.output keyfile*.key 
 
echo "Running order2vec.pl --format f6.3 test-A4.sval2 test-A42.wordvec test-A4.regex"

order2vec.pl --format f6.3 test-A4.sval2 test-A42.wordvec test-A4.regex > test-A4.output

diff -w test-A4.output test-A42.reqd > var1
diff -w test-A4.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A42.reqd";
        cat var1;
        echo "When tested against test-A4.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A4.output keyfile*.key
