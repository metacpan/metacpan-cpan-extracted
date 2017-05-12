#!/bin/csh

echo "Test A6 for order1vec.pl"
echo "Running order1vec.pl --dense test-A6.sval2 test-A6.regex"

order1vec.pl --dense test-A6.sval2 test-A6.regex > test-A6a.output

diff -w test-A6a.output test-A6a.reqd > var1
diff -w test-A6.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A6a.reqd";
	cat var1;
	echo "When tested against test-A6.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A6a.output keyfile*.key

echo "Running order1vec.pl test-A6.sval2 test-A6.regex"

order1vec.pl test-A6.sval2 test-A6.regex > test-A6b.output

diff -w test-A6b.output test-A6b.reqd > var1
diff -w test-A6.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A6b.reqd";
        cat var1;
        echo "When tested against test-A6.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A6b.output keyfile*.key
