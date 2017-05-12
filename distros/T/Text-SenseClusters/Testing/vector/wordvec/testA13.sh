#!/bin/csh

echo "Test A13 for wordvec.pl"
echo "Running wordvec.pl --dense --format f6.3 --feats test-A13a.feats --dims test-A13a.dims test-A13.bi"

wordvec.pl --dense --format f6.3 --feats test-A13a.feats --dims test-A13a.dims test-A13.bi > test-A13a1.output

diff test-A13a1.output test-A13a1.reqd > var1
diff test-A13a.dims test-A13a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A13a1.reqd";
	cat var1;
	echo "When tested against test-A13a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A13a.dims test-A13a1.output

echo "Running wordvec.pl --format f6.3 --feats test-A13a.feats --dims test-A13a.dims test-A13.bi"

wordvec.pl --format f6.3 --feats test-A13a.feats --dims test-A13a.dims test-A13.bi > test-A13a2.output

diff -w test-A13a2.output test-A13a2.reqd > var1
diff -w test-A13a.dims test-A13a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A13a2.reqd";
        cat var1;
        echo "When tested against test-A13a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A13a.dims test-A13a2.output

echo "Running wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A13b.feats --dims test-A13b.dims test-A13.bi"

wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A13b.feats --dims test-A13b.dims test-A13.bi > test-A13b1.output

diff test-A13b1.output test-A13b1.reqd > var1
diff test-A13b.dims test-A13b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A13b1.reqd";
        cat var1;
        echo "When tested against test-A13b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A13b.dims test-A13b1.output

echo "Running wordvec.pl --format f6.3 --wordorder precede --feats test-A13b.feats --dims test-A13b.dims test-A13.bi"

wordvec.pl --format f6.3 --wordorder precede --feats test-A13b.feats --dims test-A13b.dims test-A13.bi > test-A13b2.output

diff -w test-A13b2.output test-A13b2.reqd > var1
diff -w test-A13b.dims test-A13b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A13b2.reqd";
        cat var1;
        echo "When tested against test-A13b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A13b.dims test-A13b2.output

echo "Running wordvec.pl  --dense --format f6.3 --wordorder nocare --feats test-A13c.feats --dims test-A13c.dims test-A13.bi"

wordvec.pl --dense --format f6.3 --wordorder nocare --feats test-A13c.feats --dims test-A13c.dims test-A13.bi > test-A13c1.output

diff test-A13c1.output test-A13c1.reqd > var1
diff test-A13c.dims test-A13c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A13c1.reqd";
        cat var1;
        echo "When tested against test-A13c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A13c.dims test-A13c1.output

echo "Running wordvec.pl  --format f6.3 --wordorder nocare --feats test-A13c.feats --dims test-A13c.dims test-A13.bi"

wordvec.pl --format f6.3 --wordorder nocare --feats test-A13c.feats --dims test-A13c.dims test-A13.bi > test-A13c2.output

diff -w test-A13c2.output test-A13c2.reqd > var1
diff -w test-A13c.dims test-A13c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A13c2.reqd";
        cat var1;
        echo "When tested against test-A13c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A13c.dims test-A13c2.output
