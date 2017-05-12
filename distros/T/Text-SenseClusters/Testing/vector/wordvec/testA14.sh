#!/bin/csh

echo "Test A14 for wordvec.pl"
echo "Running wordvec.pl --dense --format i3 --feats test-A14a.feats --dims test-A14a.dims test-A14.bi"

wordvec.pl --dense --format i3 --feats test-A14a.feats --dims test-A14a.dims test-A14.bi > test-A14a1.output

diff -w test-A14a1.output test-A14a1.reqd > var1
diff -w test-A14a.dims test-A14a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A14a1.reqd";
	cat var1;
	echo "When tested against test-A14a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A14a.dims test-A14a1.output

echo "Running wordvec.pl --format i3 --feats test-A14a.feats --dims test-A14a.dims test-A14.bi"

wordvec.pl --format i3 --feats test-A14a.feats --dims test-A14a.dims test-A14.bi > test-A14a2.output

diff -w test-A14a2.output test-A14a2.reqd > var1
diff -w test-A14a.dims test-A14a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A14a2.reqd";
        cat var1;
        echo "When tested against test-A14a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A14a.dims test-A14a2.output

echo "Running wordvec.pl --dense --format i3 --wordorder precede --feats test-A14b.feats --dims test-A14b.dims test-A14.bi"

wordvec.pl --dense --format i3 --wordorder precede --feats test-A14b.feats --dims test-A14b.dims test-A14.bi > test-A14b1.output

diff -w test-A14b1.output test-A14b1.reqd > var1
diff -w test-A14b.dims test-A14b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A14b1.reqd";
        cat var1;
        echo "When tested against test-A14b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A14b.dims test-A14b1.output

echo "Running wordvec.pl --format i3 --wordorder precede --feats test-A14b.feats --dims test-A14b.dims test-A14.bi"

wordvec.pl --format i3 --wordorder precede --feats test-A14b.feats --dims test-A14b.dims test-A14.bi > test-A14b2.output

diff -w test-A14b2.output test-A14b2.reqd > var1
diff -w test-A14b.dims test-A14b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A14b2.reqd";
        cat var1;
        echo "When tested against test-A14b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A14b.dims test-A14b2.output

echo "Running wordvec.pl --dense --format i3 --wordorder nocare --feats test-A14c.feats --dims test-A14c.dims test-A14.bi"

wordvec.pl --dense --format i3 --wordorder nocare --feats test-A14c.feats --dims test-A14c.dims test-A14.bi > test-A14c1.output

diff -w test-A14c1.output test-A14c1.reqd > var1
diff -w test-A14c.dims test-A14c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A14c1.reqd";
        cat var1;
        echo "When tested against test-A14c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A14c.dims test-A14c1.output

echo "Running wordvec.pl --format i3 --wordorder nocare --feats test-A14c.feats --dims test-A14c.dims test-A14.bi"

wordvec.pl --format i3 --wordorder nocare --feats test-A14c.feats --dims test-A14c.dims test-A14.bi > test-A14c2.output

diff -w test-A14c2.output test-A14c2.reqd > var1
diff -w test-A14c.dims test-A14c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A14c2.reqd";
        cat var1;
        echo "When tested against test-A14c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A14c.dims test-A14c2.output
