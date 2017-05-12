#!/bin/csh

echo "Test A10 for wordvec.pl"
echo "Running wordvec.pl --dense --extarget --format i3 --feats test-A10a.feats --dims test-A10a.dims test-A10.bi"

wordvec.pl --dense --extarget --format i3 --feats test-A10a.feats --dims test-A10a.dims test-A10.bi > test-A10a1.output

diff test-A10a1.output test-A10a1.reqd > var1
diff -w test-A10a.feats test-A10a.feats.reqd > var2
diff -w test-A10a.dims test-A10a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A10a1.reqd";
	cat var1;
	echo "When tested against test-A10a.feats.reqd";
        cat var2;
	echo "When tested against test-A10a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A10a.feats test-A10a.dims test-A10a1.output

echo "Running wordvec.pl --extarget --format i3 --feats test-A10a.feats --dims test-A10a.dims test-A10.bi"

wordvec.pl --extarget --format i3 --feats test-A10a.feats --dims test-A10a.dims test-A10.bi > test-A10a2.output

diff -w test-A10a2.output test-A10a2.reqd > var1
diff -w test-A10a.feats test-A10a.feats.reqd > var2
diff -w test-A10a.dims test-A10a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10a2.reqd";
        cat var1;
        echo "When tested against test-A10a.feats.reqd";
        cat var2;
        echo "When tested against test-A10a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A10a.feats test-A10a.dims test-A10a2.output

echo "Running wordvec.pl --wordorder precede --dense --extarget --format i3 --feats test-A10b.feats --dims test-A10b.dims test-A10.bi"

wordvec.pl --wordorder precede --dense --extarget --format i3 --feats test-A10b.feats --dims test-A10b.dims test-A10.bi > test-A10b1.output

diff test-A10b1.output test-A10b1.reqd > var1
diff -w test-A10b.feats test-A10b.feats.reqd > var2
diff -w test-A10b.dims test-A10b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10b1.reqd";
        cat var1;
        echo "When tested against test-A10b.feats.reqd";
        cat var2;
        echo "When tested against test-A10b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A10b.feats test-A10b.dims test-A10b1.output

echo "Running wordvec.pl --format i3 --extarget --wordorder precede --feats test-A10b.feats --dims test-A10b.dims test-A10.bi"

wordvec.pl --format i3 --extarget --wordorder precede --feats test-A10b.feats --dims test-A10b.dims test-A10.bi > test-A10b2.output

diff -w test-A10b2.output test-A10b2.reqd > var1
diff -w test-A10b.feats test-A10b.feats.reqd > var2
diff -w test-A10b.dims test-A10b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10b2.reqd";
        cat var1;
        echo "When tested against test-A10b.feats.reqd";
        cat var2;
        echo "When tested against test-A10b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A10b.feats test-A10b.dims test-A10b2.output

echo "Running wordvec.pl --dense --format i3 --extarget --wordorder nocare --feats test-A10c.feats --dims test-A10c.dims test-A10.bi"

wordvec.pl --dense --format i3 --extarget --wordorder nocare --feats test-A10c.feats --dims test-A10c.dims test-A10.bi > test-A10c1.output

diff test-A10c1.output test-A10c1.reqd > var1
diff -w test-A10c.feats test-A10c.feats.reqd > var2
diff -w test-A10c.dims test-A10c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10c1.reqd";
        cat var1;
        echo "When tested against test-A10c.feats.reqd";
        cat var2;
        echo "When tested against test-A10c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A10c.feats test-A10c.dims test-A10c1.output

echo "Running wordvec.pl --format i3 --extarget --wordorder nocare --feats test-A10c.feats --dims test-A10c.dims test-A10.bi"

wordvec.pl --format i3 --extarget --wordorder nocare --feats test-A10c.feats --dims test-A10c.dims test-A10.bi > test-A10c2.output

diff -w test-A10c2.output test-A10c2.reqd > var1
diff -w test-A10c.feats test-A10c.feats.reqd > var2
diff -w test-A10c.dims test-A10c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10c2.reqd";
        cat var1;
        echo "When tested against test-A10c.feats.reqd";
        cat var2;
        echo "When tested against test-A10c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A10c.feats test-A10c.dims test-A10c2.output
