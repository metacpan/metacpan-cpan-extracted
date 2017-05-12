#!/bin/csh

echo "Test A7 for order1vec.pl"
echo "Running order1vec.pl --dense test-A7.sval2 test-A7.regex"

order1vec.pl --dense test-A7.sval2 test-A7.regex > test-A7a.output

diff -w test-A7a.output test-A7a.reqd > var1
diff -w test-A7.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A7a.reqd";
	cat var1;
	echo "When tested against test-A7.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A7a.output keyfile*.key

echo "Running order1vec.pl test-A7.sval2 test-A7.regex"

order1vec.pl test-A7.sval2 test-A7.regex > test-A7b.output

diff -w test-A7b.output test-A7b.reqd > var1
diff -w test-A7.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A7b.reqd";
        cat var1;
        echo "When tested against test-A7.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A7b.output keyfile*.key
