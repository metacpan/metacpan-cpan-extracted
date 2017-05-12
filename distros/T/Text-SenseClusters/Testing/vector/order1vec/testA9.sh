#!/bin/csh

echo "Test A9 for order1vec.pl"
echo "Running order1vec.pl --dense --extarget --binary test-A91.sval2 test-A91.regex"

order1vec.pl --dense --extarget --binary test-A91.sval2 test-A91.regex > test-A91a.output

diff -w test-A91a.output test-A91a.reqd > var1
diff -w test-A91.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A91a.reqd";
	cat var1;
	echo "When tested against test-A91.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A91a.output
/bin/rm -f keyfile*.key

echo "Running order1vec.pl --extarget --binary test-A91.sval2 test-A91.regex"

order1vec.pl --extarget --binary test-A91.sval2 test-A91.regex > test-A91b.output

diff -w test-A91b.output test-A91b.reqd > var1
diff -w test-A91.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A91b.reqd";
        cat var1;
        echo "When tested against test-A91.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A91b.output
/bin/rm -f keyfile*.key

echo "Running order1vec.pl --dense --extarget --target test-A92.target test-A92.sval2 test-A92.regex"

order1vec.pl --dense --extarget --target test-A92.target test-A92.sval2 test-A92.regex > test-A92a.output

diff -w test-A92a.output test-A92a.reqd > var1
diff -w test-A92.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A92a.reqd";
        cat var1;
        echo "When tested against test-A92.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A92a.output keyfile*.key 

echo "Running order1vec.pl --extarget --target test-A92.target test-A92.sval2 test-A92.regex"

order1vec.pl --extarget --target test-A92.target test-A92.sval2 test-A92.regex > test-A92b.output

diff -w test-A92b.output test-A92b.reqd > var1
diff -w test-A92.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A92b.reqd";
        cat var1;
        echo "When tested against test-A92.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A92b.output keyfile*.key

echo "Running order1vec.pl --dense --extarget --target test-A93.target test-A93.sval2 test-A93.regex"

order1vec.pl --dense --extarget --target test-A93.target test-A93.sval2 test-A93.regex > test-A93a.output

diff -w test-A93a.output test-A93a.reqd > var1
diff -w test-A93.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A93a.reqd";
        cat var1;
        echo "When tested against test-A93.key";
        cat var2;
endif

/bin/rm -f test-A93a.output var1 var2 keyfile*.key

echo "Running order1vec.pl --extarget --target test-A93.target test-A93.sval2 test-A93.regex"

order1vec.pl --extarget --target test-A93.target test-A93.sval2 test-A93.regex > test-A93b.output

diff -w test-A93b.output test-A93b.reqd > var1
diff -w test-A93.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A93b.reqd";
        cat var1;
        echo "When tested against test-A93.key";
        cat var2;
endif

/bin/rm -f test-A93b.output var1 var2 keyfile*.key

echo "Running order1vec.pl --dense --extarget --target test-A94.target test-A94.sval2 test-A94.regex"

order1vec.pl --dense --extarget --target test-A94.target test-A94.sval2 test-A94.regex > test-A94a.output

diff -w test-A94a.output test-A94a.reqd > var1
diff -w test-A94.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A94a.reqd";
        cat var1;
        echo "When tested against test-A94.key";
        cat var2;
endif

/bin/rm -f test-A94a.output var1 var2 keyfile*.key

echo "Running order1vec.pl --extarget --target test-A94.target test-A94.sval2 test-A94.regex"

order1vec.pl --extarget --target test-A94.target test-A94.sval2 test-A94.regex > test-A94b.output

diff -w test-A94b.output test-A94b.reqd > var1
diff -w test-A94.key keyfile*.key > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A94b.reqd";
        cat var1;
        echo "When tested against test-A94.key";
        cat var2;
endif

/bin/rm -f test-A94b.output var1 var2 keyfile*.key
