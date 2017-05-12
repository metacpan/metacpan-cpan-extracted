#!/bin/csh

echo "Test A8 for order1vec.pl"
echo "Running order1vec.pl --dense --rlabel test-A8.rlabel --clabel test-A8.clabel --rclass test-A8.rclass test-A8.sval2 test-A8.regex"

order1vec.pl --dense --rlabel test-A8.rlabel --clabel test-A8.clabel --rclass test-A8.rclass test-A8.sval2 test-A8.regex > test-A8a.output

diff -w test-A8a.output test-A8a.reqd > var1
diff -w test-A8.key keyfile*.key > var2
diff -w test-A8.rlabel test-A8.rlabel.reqd > var3
diff -w test-A8.rclass test-A8.rclass.reqd > var4
diff -w test-A8.clabel test-A8.clabel.reqd > var5

if(-z var1 && -z var2 && -z var3 && -z var4 && -z var5) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A8a.reqd";
	cat var1;
	echo "When tested against test-A8.key";
        cat var2;
	echo "When tested against test-A8.rlabel";
        cat var3;
	echo "When tested against test-A8.rclass";
        cat var4;
	echo "When tested against test-A8.clabel";
        cat var5;
endif

/bin/rm -f test-A8a.output var1 var2 var3 var4 var5 test-A8.rlabel test-A8.clabel test-A8.rclass
/bin/rm -f keyfile*.key

echo "Running order1vec.pl --rlabel test-A8.rlabel --clabel test-A8.clabel --rclass test-A8.rclass test-A8.sval2 test-A8.regex"

order1vec.pl --rlabel test-A8.rlabel --clabel test-A8.clabel --rclass test-A8.rclass test-A8.sval2 test-A8.regex > test-A8b.output

diff -w test-A8b.output test-A8b.reqd > var1
diff -w test-A8.key keyfile*.key > var2
diff -w test-A8.rlabel test-A8.rlabel.reqd > var3
diff -w test-A8.rclass test-A8.rclass.reqd > var4
diff -w test-A8.clabel test-A8.clabel.reqd > var5

if(-z var1 && -z var2 && -z var3 && -z var4 && -z var5) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8b.reqd";
        cat var1;
        echo "When tested against test-A8.key";
        cat var2;
        echo "When tested against test-A8.rlabel";
        cat var3;
        echo "When tested against test-A8.rclass";
        cat var4;
        echo "When tested against test-A8.clabel";
        cat var5;
endif

/bin/rm -f test-A8b.output var1 var2 var3 var4 var5 test-A8.rlabel test-A8.clabel test-A8.rclass
/bin/rm -f keyfile*.key
