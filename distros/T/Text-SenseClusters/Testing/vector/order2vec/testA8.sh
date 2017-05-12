#!/bin/csh

echo "Test A8a for order2vec.pl"
echo "Running order2vec.pl --dense --binary test-A8.sval2 test-A8a1.wordvec test-A8.regex"

order2vec.pl --dense --binary test-A8.sval2 test-A8a1.wordvec test-A8.regex > test-A8a.output

diff -w test-A8a1.reqd test-A8a.output > var1

if(-z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A8a1.reqd";
	cat var1;
endif

/bin/rm -f var1 test-A8a.output keyfile*.key

echo "Running order2vec.pl --binary test-A8.sval2 test-A8a2.wordvec test-A8.regex"

order2vec.pl --binary test-A8.sval2 test-A8a2.wordvec test-A8.regex > test-A8a.output

diff -w test-A8a2.reqd test-A8a.output > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8a2.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A8a.output keyfile*.key 

echo "Test A8b for order2vec.pl"
echo "Running order2vec.pl --dense --binary --format i5 test-A8.sval2 test-A8b1.wordvec test-A8.regex"

order2vec.pl --dense --binary --format i5 test-A8.sval2 test-A8b1.wordvec test-A8.regex > test-A8b.output

diff -w test-A8b1.reqd test-A8b.output > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8b1.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A8b.output keyfile*.key

echo "Running order2vec.pl --binary --format i5 test-A8.sval2 test-A8b2.wordvec test-A8.regex"

order2vec.pl --binary --format i5 test-A8.sval2 test-A8b2.wordvec test-A8.regex > test-A8b.output

diff -w test-A8b2.reqd test-A8b.output > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8b2.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A8b.output keyfile*.key

echo "Test A8c for order2vec.pl"
echo "Running order2vec.pl --dense --binary --format f6.3 test-A8.sval2 test-A8c1.wordvec test-A8.regex"

order2vec.pl --dense --binary --format f6.3 test-A8.sval2 test-A8c1.wordvec test-A8.regex > test-A8c.output

diff -w test-A8c1.reqd test-A8c.output > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8c1.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A8c.output keyfile*.key

echo "Running order2vec.pl --binary --format f6.3 test-A8.sval2 test-A8c2.wordvec test-A8.regex"

order2vec.pl --binary --format f6.3 test-A8.sval2 test-A8c2.wordvec test-A8.regex > test-A8c.output

diff -w test-A8c2.reqd test-A8c.output > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8c2.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A8c.output keyfile*.key
