#!/bin/csh

echo "Test A2 for wordvec.pl"
echo "Running wordvec.pl --dense --format i3 --feats test-A2a.feats --dims test-A2a.dims test-A2.bi"

wordvec.pl --dense --format i3 --feats test-A2a.feats --dims test-A2a.dims test-A2.bi > test-A2a1.output

diff test-A2a1.output test-A2a1.reqd > var1
diff test-A2a.feats test-A2a.feats.reqd > var2
diff test-A2a.dims test-A2a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2a1.reqd";
	cat var1;
	echo "When tested against test-A2a.feats.reqd";
        cat var2;
	echo "When tested against test-A2a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A2a.feats test-A2a.dims test-A2a1.output

echo "Running wordvec.pl --format i3 --feats test-A2a.feats --dims test-A2a.dims test-A2.bi"

wordvec.pl --format i3 --feats test-A2a.feats --dims test-A2a.dims test-A2.bi > test-A2a2.output

diff -w test-A2a2.output test-A2a2.reqd > var1
diff -w test-A2a.feats test-A2a.feats.reqd > var2
diff -w test-A2a.dims test-A2a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2a2.reqd";
        cat var1;
        echo "When tested against test-A2a.feats.reqd";
        cat var2;
        echo "When tested against test-A2a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A2a.feats test-A2a.dims test-A2a2.output

echo "Running wordvec.pl --dense --format i3 --wordorder precede --feats test-A2b.feats --dims test-A2b.dims test-A2.bi"

wordvec.pl --dense --format i3 --wordorder precede --feats test-A2b.feats --dims test-A2b.dims test-A2.bi > test-A2b1.output

diff test-A2b1.output test-A2b1.reqd > var1
diff test-A2b.feats test-A2b.feats.reqd > var2
diff test-A2b.dims test-A2b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2b1.reqd";
        cat var1;
        echo "When tested against test-A2b.feats.reqd";
        cat var2;
        echo "When tested against test-A2b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A2b.feats test-A2b.dims test-A2b1.output

echo "Running wordvec.pl --format i3 --wordorder precede --feats test-A2b.feats --dims test-A2b.dims test-A2.bi"

wordvec.pl --format i3 --wordorder precede --feats test-A2b.feats --dims test-A2b.dims test-A2.bi > test-A2b2.output

diff -w test-A2b2.output test-A2b2.reqd > var1
diff -w test-A2b.feats test-A2b.feats.reqd > var2
diff -w test-A2b.dims test-A2b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2b2.reqd";
        cat var1;
        echo "When tested against test-A2b.feats.reqd";
        cat var2;
        echo "When tested against test-A2b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A2b.feats test-A2b.dims test-A2b2.output

echo "Running wordvec.pl --dense --format i3 --wordorder nocare --feats test-A2c.feats --dims test-A2c.dims test-A2.bi"

wordvec.pl --dense --format i3 --wordorder nocare --feats test-A2c.feats --dims test-A2c.dims test-A2.bi >& test-A2c1.output

diff -w test-A2c1.output test-A2c1.reqd > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2c1.reqd";
        cat var1;
endif

/bin/rm -f var1 var2 test-A2c1.output

echo "Running wordvec.pl --format i3 --wordorder nocare --feats test-A2c.feats --dims test-A2c.dims test-A2.bi"

wordvec.pl --format i3 --wordorder nocare --feats test-A2c.feats --dims test-A2c.dims test-A2.bi >& test-A2c2.output

diff -w test-A2c2.output test-A2c2.reqd > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2c2.reqd";
        cat var1;
endif

/bin/rm -f var1 var2 test-A2c2.output
