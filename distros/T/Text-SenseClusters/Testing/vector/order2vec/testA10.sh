#!/bin/csh

echo "Test A10 for order2vec.pl"
echo "Running order2vec.pl --format f16.06 test-A10.sval2 test-A10.wordvec test-A10.regex"

order2vec.pl --format f16.06 test-A10.sval2 test-A101.wordvec test-A10.regex > test-A101.output

diff -w test-A101.output test-A101.reqd > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A101.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A101.output 
/bin/rm -f keyfile*.key 

echo "Running order2vec.pl --format f16.06 --binary test-A10.sval2 test-A10.wordvec test-A10.regex"

order2vec.pl --format f16.06 --binary test-A10.sval2 test-A102.wordvec test-A10.regex > test-A102.output

diff -w test-A102.output test-A102.reqd > var2

if(-z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A102.reqd";
	cat var2;
endif

/bin/rm -f var2 test-A102.output 
/bin/rm -f keyfile*.key 


