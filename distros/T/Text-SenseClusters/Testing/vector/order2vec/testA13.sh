#!/bin/csh

echo "Test A13 for order2vec.pl"
echo "Running order2vec.pl --format f16.06 test-A13.sval2 test-A13.wordvec test-A13.regex"

order2vec.pl --format f16.06 test-A13.sval2 test-A131.wordvec test-A13.regex > test-A131.output

diff -w test-A131.output test-A131.reqd > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A131.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A131.output 
/bin/rm -f keyfile*.key 

echo "Running order2vec.pl --format f16.06 --binary test-A13.sval2 test-A13.wordvec test-A13.regex"

order2vec.pl --format f16.06 --binary test-A13.sval2 test-A132.wordvec test-A13.regex > test-A132.output

diff -w test-A132.output test-A132.reqd > var2

if(-z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A132.reqd";
	cat var2;
endif

/bin/rm -f var2 test-A132.output 
/bin/rm -f keyfile*.key 


