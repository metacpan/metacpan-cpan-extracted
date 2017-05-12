#!/bin/csh

echo "Test A11 for wordvec.pl"
echo "Running wordvec.pl --dense --format i2 --feats test-A11a.feats --dims test-A11a.dims test-A11.bi"

wordvec.pl --dense --format i2 --feats test-A11a.feats --dims test-A11a.dims test-A11.bi > test-A11a1.output

diff test-A11a1.output test-A11a1.reqd > var1
diff test-A11a.dims test-A11a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A11a1.reqd";
	cat var1;
	echo "When tested against test-A11a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A11a.dims test-A11a1.output

echo "Running wordvec.pl --format i2 --feats test-A11a.feats --dims test-A11a.dims test-A11.bi"

wordvec.pl --format i2 --feats test-A11a.feats --dims test-A11a.dims test-A11.bi > test-A11a2.output

diff -w test-A11a2.output test-A11a2.reqd > var1
diff -w test-A11a.dims test-A11a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A11a2.reqd";
        cat var1;
        echo "When tested against test-A11a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A11a.dims test-A11a2.output

echo "Running wordvec.pl --dense --format i2 --wordorder precede --feats test-A11b.feats --dims test-A11b.dims test-A11.bi"

wordvec.pl --dense --format i2 --wordorder precede --feats test-A11b.feats --dims test-A11b.dims test-A11.bi > test-A11b1.output

diff test-A11b1.output test-A11b1.reqd > var1
diff test-A11b.dims test-A11b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A11b1.reqd";
        cat var1;
        echo "When tested against test-A11b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A11b.dims test-A11b1.output

echo "Running wordvec.pl --format i2 --wordorder precede --feats test-A11b.feats --dims test-A11b.dims test-A11.bi"

wordvec.pl --format i2 --wordorder precede --feats test-A11b.feats --dims test-A11b.dims test-A11.bi > test-A11b2.output

diff -w test-A11b2.output test-A11b2.reqd > var1
diff -w test-A11b.dims test-A11b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A11b2.reqd";
        cat var1;
        echo "When tested against test-A11b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A11b.dims test-A11b2.output

echo "Running wordvec.pl --dense --format i2 --wordorder nocare --feats test-A11c.feats --dims test-A11c.dims test-A11.bi"

wordvec.pl --dense --format i2 --wordorder nocare --feats test-A11c.feats --dims test-A11c.dims test-A11.bi > test-A11c1.output

diff test-A11c1.output test-A11c1.reqd > var1
diff test-A11c.dims test-A11c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A11c1.reqd";
        cat var1;
        echo "When tested against test-A11c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A11c.dims test-A11c1.output

echo "Running wordvec.pl --format i2 --wordorder nocare --feats test-A11c.feats --dims test-A11c.dims test-A11.bi"

wordvec.pl --format i2 --wordorder nocare --feats test-A11c.feats --dims test-A11c.dims test-A11.bi > test-A11c2.output

diff -w test-A11c2.output test-A11c2.reqd > var1
diff -w test-A11c.dims test-A11c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A11c2.reqd";
        cat var1;
        echo "When tested against test-A11c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A11c.dims test-A11c2.output
