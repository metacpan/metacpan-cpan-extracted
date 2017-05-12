#!/bin/csh

echo "Test A3 for order1vec.pl"
echo "Running order1vec.pl --dense test-A3.sval2 test-A3.regex"

order1vec.pl --dense test-A3.sval2 test-A3.regex > test-A3a.output

diff -w test-A3a.output test-A3a.reqd > var1
diff -w test-A3.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3a.reqd";
	cat var1;
	echo "When tested against test-A3.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A3a.output keyfile*.key

echo "Running order1vec.pl test-A3.sval2 test-A3.regex"

order1vec.pl test-A3.sval2 test-A3.regex > test-A3b.output

diff -w test-A3b.output test-A3b.reqd > var1
diff -w test-A3.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3b.reqd";
        cat var1;
        echo "When tested against test-A3.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A3b.output keyfile*.key
