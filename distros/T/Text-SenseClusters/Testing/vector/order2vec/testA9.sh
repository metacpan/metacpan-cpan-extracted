#!/bin/csh

echo "Test A9 for order2vec.pl"
echo "Running order2vec.pl --dense --format f6.3 test-A9.sval2 test-A91.wordvec test-A9.regex"

order2vec.pl --dense --format f6.3 test-A9.sval2 test-A91.wordvec test-A9.regex > test-A9.output

diff -w test-A9.output test-A91.reqd > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A91.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A9.output 
/bin/rm -f keyfile*.key 

echo "Running order2vec.pl --format f6.3 test-A9.sval2 test-A92.wordvec test-A9.regex"

order2vec.pl --format f6.3 test-A9.sval2 test-A92.wordvec test-A9.regex > test-A9.output

diff -w test-A9.output test-A92.reqd > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A92.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A9.output
/bin/rm -f keyfile*.key

