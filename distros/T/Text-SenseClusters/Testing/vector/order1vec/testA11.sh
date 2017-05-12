#!/bin/csh

echo "Test A11 for order1vec.pl"
echo "Running order1vec.pl --extarget --target test-A11.target test-A11.sval2 test-A11.regex"

order1vec.pl --extarget --target test-A11.target test-A11.sval2 test-A11.regex > test-A11.output

diff -w test-A11.output test-A11.reqd > var1
diff -w test-A11.key keyfile*.key > var2

if(-z var1 && -z var2) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A11.reqd";
	cat var1;
	echo "When tested against test-A11.key";
        cat var2;
endif

/bin/rm -f var1 var2 test-A11.output
/bin/rm -f keyfile*.key
