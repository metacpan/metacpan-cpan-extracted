#!/bin/csh

echo "Test A3 for order2vec.pl"
echo "Running order2vec.pl --dense --format f7.4 test-A3.sval2 test-A31.wordvec test-A3.regex"

order2vec.pl --dense --format f7.4 test-A3.sval2 test-A31.wordvec test-A3.regex > test-A3.output

diff -w test-A3.output test-A31.reqd > var1

diff -w test-A3.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A31.reqd";
	cat var1;
	echo "When tested against test-A3.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A3.output keyfile*.key
 
echo "Running order2vec.pl --format f7.4 test-A3.sval2 test-A32.wordvec test-A3.regex"

order2vec.pl --format f7.4 test-A3.sval2 test-A32.wordvec test-A3.regex > test-A3.output

diff -w test-A3.output test-A32.reqd > var1
diff -w test-A3.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A32.reqd";
        cat var1;
        echo "When tested against test-A3.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A3.output keyfile*.key
