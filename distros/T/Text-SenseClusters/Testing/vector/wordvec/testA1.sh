#!/bin/csh

echo "Test A1 for wordvec.pl"
echo "Running wordvec.pl --dense --format i2 --feats test-A1a.feats --dims test-A1a.dims test-A1.bi"

wordvec.pl --dense --format i2 --feats test-A1a.feats --dims test-A1a.dims test-A1.bi > test-A1a1.output

diff test-A1a1.output test-A1a1.reqd > var1
diff test-A1a.feats test-A1a.feats.reqd > var2
diff test-A1a.dims test-A1a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1a1.reqd";
	cat var1;
	echo "When tested against test-A1a.feats.reqd";
        cat var2;
	echo "When tested against test-A1a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A1a.feats test-A1a.dims test-A1a1.output

echo "Running wordvec.pl --format i2 --feats test-A1a.feats --dims test-A1a.dims test-A1.bi"

wordvec.pl --format i2 --feats test-A1a.feats --dims test-A1a.dims test-A1.bi > test-A1a2.output

diff -w test-A1a2.output test-A1a2.reqd > var1
diff -w test-A1a.feats test-A1a.feats.reqd > var2
diff -w test-A1a.dims test-A1a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1a2.reqd";
        cat var1;
        echo "When tested against test-A1a.feats.reqd";
        cat var2;
        echo "When tested against test-A1a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A1a.feats test-A1a.dims test-A1a2.output

echo "Running wordvec.pl --dense --format i2 --wordorder precede --feats test-A1b.feats --dims test-A1b.dims test-A1.bi"

wordvec.pl --dense --format i2 --wordorder precede --feats test-A1b.feats --dims test-A1b.dims test-A1.bi > test-A1b1.output

diff test-A1b1.output test-A1b1.reqd > var1
diff test-A1b.feats test-A1b.feats.reqd > var2
diff test-A1b.dims test-A1b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1b1.reqd";
        cat var1;
        echo "When tested against test-A1b.feats.reqd";
        cat var2;
        echo "When tested against test-A1b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A1b.feats test-A1b.dims test-A1b1.output

echo "Running wordvec.pl --format i2 --wordorder precede --feats test-A1b.feats --dims test-A1b.dims test-A1.bi"

wordvec.pl --format i2 --wordorder precede --feats test-A1b.feats --dims test-A1b.dims test-A1.bi > test-A1b2.output

diff -w test-A1b2.output test-A1b2.reqd > var1
diff -w test-A1b.feats test-A1b.feats.reqd > var2
diff -w test-A1b.dims test-A1b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1b2.reqd";
        cat var1;
        echo "When tested against test-A1b.feats.reqd";
        cat var2;
        echo "When tested against test-A1b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A1b.feats test-A1b.dims test-A1b2.output

echo "Running wordvec.pl --dense --format i2 --wordorder nocare --feats test-A1c.feats --dims test-A1c.dims test-A1.bi"

wordvec.pl --dense --format i2 --wordorder nocare --feats test-A1c.feats --dims test-A1c.dims test-A1.bi > test-A1c1.output

diff test-A1c1.output test-A1c1.reqd > var1
diff test-A1c.feats test-A1c.feats.reqd > var2
diff test-A1c.dims test-A1c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1c1.reqd";
        cat var1;
	echo "When tested against test-A1c.feats.reqd";
        cat var2;
        echo "When tested against test-A1c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A1c.feats test-A1c.dims test-A1c1.output

echo "Running wordvec.pl --format i2 --wordorder nocare --feats test-A1c.feats --dims test-A1c.dims test-A1.bi"

wordvec.pl --format i2 --wordorder nocare --feats test-A1c.feats --dims test-A1c.dims test-A1.bi > test-A1c2.output

diff -w test-A1c2.output test-A1c2.reqd > var1
diff -w test-A1c.feats test-A1c.feats.reqd > var2
diff -w test-A1c.dims test-A1c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1c2.reqd";
        cat var1;
        echo "When tested against test-A1c.feats.reqd";
        cat var2;
        echo "When tested against test-A1c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A1c.feats test-A1c.dims test-A1c2.output
