#!/bin/csh

echo "Test A10 for order1vec.pl"
echo "Running order1vec.pl --dense test-A10.sval2 test-A10.regex"

order1vec.pl --dense test-A10.sval2 test-A10.regex > test-A10a.output

diff -w test-A10a.output test-A10a.reqd > var1

diff -w test-A10.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A10a.reqd";
	cat var1;
	echo "When tested against test-A10.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A10a.output keyfile*.key 

echo "Running order1vec.pl test-A10.sval2 test-A10.regex"

order1vec.pl test-A10.sval2 test-A10.regex > test-A10b.output

diff -w test-A10b.output test-A10b.reqd > var1

diff -w test-A10.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10b.reqd";
        cat var1;
        echo "When tested against test-A10.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A10b.output keyfile*.key
