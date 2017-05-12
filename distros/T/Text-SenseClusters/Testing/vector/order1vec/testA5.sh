#!/bin/csh

echo "Test A5 for order1vec.pl"
echo "Running order1vec.pl --dense test-A5.sval2 test-A5.regex"

order1vec.pl --dense test-A5.sval2 test-A5.regex > test-A5a.output

diff -w test-A5a.output test-A5a.reqd > var1
diff -w test-A5.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A5a.reqd";
	cat var1;
	echo "When tested against test-A5.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A5a.output keyfile*.key

echo "Running order1vec.pl test-A5.sval2 test-A5.regex"

order1vec.pl test-A5.sval2 test-A5.regex > test-A5b.output

diff -w test-A5b.output test-A5b.reqd > var1
diff -w test-A5.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5b.reqd";
        cat var1;
        echo "When tested against test-A5.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A5b.output keyfile*.key
