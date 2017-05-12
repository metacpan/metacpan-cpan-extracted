#!/bin/csh

echo "Test A12 for order2vec.pl"
echo "Running order2vec.pl --format f16.06 test-A12.sval2 test-A12.wordvec test-A12.regex"

order2vec.pl --format f16.06 test-A12.sval2 test-A121.wordvec test-A12.regex > test-A121.output

diff -w test-A121.output test-A121.reqd > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A121.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A121.output 
/bin/rm -f keyfile*.key 

echo "Running order2vec.pl --format f16.06 --binary test-A12.sval2 test-A12.wordvec test-A12.regex"

order2vec.pl --format f16.06 --binary test-A12.sval2 test-A122.wordvec test-A12.regex > test-A122.output

diff -w test-A122.output test-A122.reqd > var2

if(-z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A122.reqd";
	cat var2;
endif

/bin/rm -f var2 test-A122.output 
/bin/rm -f keyfile*.key 


