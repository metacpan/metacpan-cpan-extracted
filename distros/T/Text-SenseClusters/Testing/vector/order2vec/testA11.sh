#!/bin/csh

echo "Test A11 for order2vec.pl"
echo "Running order2vec.pl --format f16.06 test-A11.sval2 test-A11.wordvec test-A11.regex"

order2vec.pl --format f16.06 test-A11.sval2 test-A111.wordvec test-A11.regex > test-A111.output

diff -w test-A111.output test-A111.reqd > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A111.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A111.output 
/bin/rm -f keyfile*.key 

echo "Running order2vec.pl --format f16.06 --binary test-A11.sval2 test-A11.wordvec test-A11.regex"

order2vec.pl --format f16.06 --binary test-A11.sval2 test-A112.wordvec test-A11.regex > test-A112.output

diff -w test-A112.output test-A112.reqd > var2

if(-z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A112.reqd";
	cat var2;
endif

/bin/rm -f var2 test-A112.output 
/bin/rm -f keyfile*.key 


