#!/bin/csh

echo "Test A1 for order1vec.pl"
echo "Running order1vec.pl --dense --binary test-A1.sval2 test-A1.regex"

order1vec.pl --dense --binary test-A1.sval2 test-A1.regex > test-A1a.output

diff -w test-A1a.output test-A1a.reqd > var1

diff -w test-A1.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1a.reqd";
	cat var1;
	echo "When tested against test-A1.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A1a.output keyfile*.key 

echo "Running order1vec.pl --binary test-A1.sval2 test-A1.regex"

order1vec.pl --binary test-A1.sval2 test-A1.regex > test-A1b.output

diff -w test-A1b.output test-A1b.reqd > var1

diff -w test-A1.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1b.reqd";
        cat var1;
        echo "When tested against test-A1.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A1b.output keyfile*.key
