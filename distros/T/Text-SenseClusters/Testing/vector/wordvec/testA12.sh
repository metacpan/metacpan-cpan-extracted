#!/bin/csh

echo "Test A12 for wordvec.pl"
echo "Running wordvec.pl --dense --format i3 --feats test-A12a.feats --dims test-A12a.dims test-A12.bi"

wordvec.pl --dense --format i3 --feats test-A12a.feats --dims test-A12a.dims test-A12.bi > test-A12a1.output

diff test-A12a1.output test-A12a1.reqd > var1
diff test-A12a.dims test-A12a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A12a1.reqd";
	cat var1;
	echo "When tested against test-A12a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A12a.dims test-A12a1.output

echo "Running wordvec.pl --format i3 --feats test-A12a.feats --dims test-A12a.dims test-A12.bi"

wordvec.pl --format i3 --feats test-A12a.feats --dims test-A12a.dims test-A12.bi > test-A12a2.output

diff -w test-A12a2.output test-A12a2.reqd > var1
diff -w test-A12a.dims test-A12a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A12a2.reqd";
        cat var1;
        echo "When tested against test-A12a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A12a.dims test-A12a2.output

echo "Running wordvec.pl --dense --format i3 --wordorder precede --feats test-A12b.feats --dims test-A12b.dims test-A12.bi"

wordvec.pl --dense --format i3 --wordorder precede --feats test-A12b.feats --dims test-A12b.dims test-A12.bi > test-A12b1.output

diff test-A12b1.output test-A12b1.reqd > var1
diff test-A12b.dims test-A12b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A12b1.reqd";
        cat var1;
        echo "When tested against test-A12b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A12b.dims test-A12b1.output

echo "Running wordvec.pl --format i3 --wordorder precede --feats test-A12b.feats --dims test-A12b.dims test-A12.bi"

wordvec.pl --format i3 --wordorder precede --feats test-A12b.feats --dims test-A12b.dims test-A12.bi > test-A12b2.output

diff -w test-A12b2.output test-A12b2.reqd > var1
diff -w test-A12b.dims test-A12b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A12b2.reqd";
        cat var1;
        echo "When tested against test-A12b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A12b.dims test-A12b2.output

echo "Running wordvec.pl --dense --format i3 --wordorder nocare --feats test-A12c.feats --dims test-A12c.dims test-A12.bi"

wordvec.pl --dense --format i3 --wordorder nocare --feats test-A12c.feats --dims test-A12c.dims test-A12.bi >& test-A12c1.output

diff -w test-A12c1.output test-A12c1.reqd > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A12c1.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A12c1.output

echo "Running wordvec.pl --format i3 --wordorder nocare --feats test-A12c.feats --dims test-A12c.dims test-A12.bi"

wordvec.pl --format i3 --wordorder nocare --feats test-A12c.feats --dims test-A12c.dims test-A12.bi >& test-A12c2.output

diff -w test-A12c2.output test-A12c2.reqd > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A12c2.reqd";
        cat var1;
endif

/bin/rm -f var1 test-A12c2.output
