#!/bin/csh

echo "Test A7 for order2vec.pl"
echo "Running order2vec.pl --dense --format f7.3 --rlabel test-A7.rlabel --rclass test-A7.rclass test-A7.sval2 test-A71.wordvec test-A7.regex"

order2vec.pl --dense --rlabel test-A7.rlabel --rclass test-A7.rclass --format f7.3 test-A7.sval2 test-A71.wordvec test-A7.regex > test-A7.output

diff -w test-A7.output test-A71.reqd > var1
diff -w test-A7.rlabel.reqd test-A7.rlabel > var2
diff -w test-A7.rclass.reqd test-A7.rclass > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A71.reqd";
	cat var1;
	cho "When tested against test-A7.rlabel";
        cat var2;
	cho "When tested against test-A7.rclass";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7.output test-A7.rlabel test-A7.rclass keyfile*.key
 
echo "Running order2vec.pl --format f7.3 --rlabel test-A7.rlabel --rclass test-A7.rclass test-A7.sval2 test-A72.wordvec test-A7.regex"

order2vec.pl --rlabel test-A7.rlabel --rclass test-A7.rclass --format f7.3 test-A7.sval2 test-A72.wordvec test-A7.regex > test-A7.output

diff -w test-A7.output test-A72.reqd > var1
diff -w test-A7.rlabel.reqd test-A7.rlabel > var2
diff -w test-A7.rclass.reqd test-A7.rclass > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A72.reqd";
        cat var1;
        cho "When tested against test-A7.rlabel";
        cat var2;
        cho "When tested against test-A7.rclass";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7.output test-A7.rlabel test-A7.rclass keyfile*.key
