#!/bin/csh

echo "Test A2 for order1vec.pl"
echo "Running order1vec.pl --dense --binary test-A2.sval2 test-A2.regex"

order1vec.pl --dense --binary test-A2.sval2 test-A2.regex > test-A2a.output

diff -w test-A2a.output test-A2a.reqd > var1
diff -w test-A2.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2a.reqd";
	cat var1;
	echo "When tested against test-A2.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A2a.output keyfile*.key

echo "Running order1vec.pl --binary test-A2.sval2 test-A2.regex"

order1vec.pl --binary test-A2.sval2 test-A2.regex > test-A2b.output

diff -w test-A2b.output test-A2b.reqd > var1
diff -w test-A2.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2b.reqd";
        cat var1;
        echo "When tested against test-A2.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A2b.output keyfile*.key
