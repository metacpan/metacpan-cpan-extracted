#!/bin/csh

echo "Test A4 for wordvec.pl"
echo "Running wordvec.pl --dense --format i3 --feats test-A4a.feats --dims test-A4a.dims test-A4.bi"

wordvec.pl --dense --format i3 --feats test-A4a.feats --dims test-A4a.dims test-A4.bi > test-A4a1.output

diff -w test-A4a1.output test-A4a1.reqd > var1
diff -w test-A4a.feats test-A4a.feats.reqd > var2
diff -w test-A4a.dims test-A4a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4a1.reqd";
	cat var1;
	echo "When tested against test-A4a.feats.reqd";
        cat var2;
	echo "When tested against test-A4a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A4a.feats test-A4a.dims test-A4a1.output

echo "Running wordvec.pl --format i3 --feats test-A4a.feats --dims test-A4a.dims test-A4.bi"

wordvec.pl --format i3 --feats test-A4a.feats --dims test-A4a.dims test-A4.bi > test-A4a2.output

diff -w test-A4a2.output test-A4a2.reqd > var1
diff -w test-A4a.feats test-A4a.feats.reqd > var2
diff -w test-A4a.dims test-A4a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4a2.reqd";
        cat var1;
        echo "When tested against test-A4a.feats.reqd";
        cat var2;
        echo "When tested against test-A4a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A4a.feats test-A4a.dims test-A4a2.output

echo "Running wordvec.pl --dense --format i3 --wordorder precede --feats test-A4b.feats --dims test-A4b.dims test-A4.bi"

wordvec.pl --dense --format i3 --wordorder precede --feats test-A4b.feats --dims test-A4b.dims test-A4.bi > test-A4b1.output

diff -w test-A4b1.output test-A4b1.reqd > var1
diff -w test-A4b.feats test-A4b.feats.reqd > var2
diff -w test-A4b.dims test-A4b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4b1.reqd";
        cat var1;
        echo "When tested against test-A4b.feats.reqd";
        cat var2;
        echo "When tested against test-A4b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A4b.feats test-A4b.dims test-A4b1.output

echo "Running wordvec.pl --format i3 --wordorder precede --feats test-A4b.feats --dims test-A4b.dims test-A4.bi"

wordvec.pl --format i3 --wordorder precede --feats test-A4b.feats --dims test-A4b.dims test-A4.bi > test-A4b2.output

diff -w test-A4b2.output test-A4b2.reqd > var1
diff -w test-A4b.feats test-A4b.feats.reqd > var2
diff -w test-A4b.dims test-A4b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4b2.reqd";
        cat var1;
        echo "When tested against test-A4b.feats.reqd";
        cat var2;
        echo "When tested against test-A4b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A4b.feats test-A4b.dims test-A4b2.output

echo "Running wordvec.pl --dense --format i3 --wordorder nocare --feats test-A4c.feats --dims test-A4c.dims test-A4.bi"

wordvec.pl --dense --format i3 --wordorder nocare --feats test-A4c.feats --dims test-A4c.dims test-A4.bi > test-A4c1.output

diff -w test-A4c1.output test-A4c1.reqd > var1
diff -w test-A4c.feats test-A4c.feats.reqd > var2
diff -w test-A4c.dims test-A4c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4c1.reqd";
        cat var1;
	echo "When tested against test-A4c.feats.reqd";
        cat var2;
        echo "When tested against test-A4c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A4c.feats test-A4c.dims test-A4c1.output

echo "Running wordvec.pl --format i3 --wordorder nocare --feats test-A4c.feats --dims test-A4c.dims test-A4.bi"

wordvec.pl --format i3 --wordorder nocare --feats test-A4c.feats --dims test-A4c.dims test-A4.bi > test-A4c2.output

diff -w test-A4c2.output test-A4c2.reqd > var1
diff -w test-A4c.feats test-A4c.feats.reqd > var2
diff -w test-A4c.dims test-A4c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A4c2.reqd";
        cat var1;
        echo "When tested against test-A4c.feats.reqd";
        cat var2;
        echo "When tested against test-A4c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A4c.feats test-A4c.dims test-A4c2.output
