#!/bin/csh

echo "Test A12 for order1vec.pl"
echo "Running order1vec.pl --transpose --testregex test-A12a.testregex --rlabel test-A12a.rlabel --clabel test-A12a.clabel --dense test-A12.sval2 test-A12.regex"

order1vec.pl --transpose --testregex test-A12a.testregex  --rlabel test-A12a.rlabel --clabel test-A12a.clabel --dense test-A12.sval2 test-A12.regex > test-A12a.output

diff -w test-A12a.output test-A12a.reqd > var1

diff -w test-A12a.testregex test-A12a.testregex.reqd > var2

diff -w test-A12a.rlabel test-A12a.rlabel.reqd > var3

diff -w test-A12a.clabel test-A12a.clabel.reqd > var4

if(-z var1 && -z var2 && -z var3 && -z var4) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A12a.reqd";
	cat var1;
	echo "When tested against test-A12a.testregex.reqd";
	cat var2;
	echo "When tested against test-A12a.rlabel.reqd";
	cat var3;
	echo "When tested against test-A12a.clabel.reqd";
	cat var4;
endif

/bin/rm -f var1 var2 var3 var4 test-A12a.output test-A12a.testregex test-A12a.rlabel test-A12a.clabel

echo "Running order1vec.pl --transpose --testregex test-A12b.testregex --rlabel test-A12b.rlabel --clabel test-A12b.clabel test-A12.sval2 test-A12.regex"

order1vec.pl --transpose --testregex test-A12b.testregex  --rlabel test-A12b.rlabel --clabel test-A12b.clabel test-A12.sval2 test-A12.regex > test-A12b.output

diff -w test-A12b.output test-A12b.reqd > var1

diff -w test-A12b.testregex test-A12b.testregex.reqd > var2

diff -w test-A12b.rlabel test-A12b.rlabel.reqd > var3

diff -w test-A12b.clabel test-A12b.clabel.reqd > var4

if(-z var1 && -z var2 && -z var3 && -z var4) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A12b.reqd";
	cat var1;
	echo "When tested against test-A12b.testregex.reqd";
	cat var2;
	echo "When tested against test-A12b.rlabel.reqd";
	cat var3;
	echo "When tested against test-A12b.clabel.reqd";
	cat var4;
endif

/bin/rm -f var1 var2 var3 var4 test-A12b.output test-A12b.testregex test-A12b.rlabel test-A12b.clabel

