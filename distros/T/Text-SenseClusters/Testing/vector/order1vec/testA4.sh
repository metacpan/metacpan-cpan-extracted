#!/bin/csh

echo "Test A4 for order1vec.pl"
echo "Running order1vec.pl --dense test-A4.sval2 test-A4.regex"

order1vec.pl --dense test-A4.sval2 test-A4.regex > test-A4a.output

diff -w test-A4a.output test-A4a.reqd > var1
diff -w test-A4.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4a.reqd";
	cat var1;
	echo "When tested against test-A4.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A4a.output keyfile*.key

echo "Running order1vec.pl test-A4.sval2 test-A4.regex"

order1vec.pl test-A4.sval2 test-A4.regex > test-A4b.output

diff -w test-A4b.output test-A4b.reqd > var1
diff -w test-A4.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4b.reqd";
        cat var1;
        echo "When tested against test-A4.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A4b.output keyfile*.key
