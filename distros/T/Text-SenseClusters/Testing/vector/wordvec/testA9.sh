#!/bin/csh

echo "Test A9 for wordvec.pl"
echo "Running wordvec.pl --dense --extarget --format i5 --feats test-A9a.feats --dims test-A9a.dims test-A9.bi"

wordvec.pl --dense --extarget --format i5 --feats test-A9a.feats --dims test-A9a.dims test-A9.bi > test-A9a1.output

diff test-A9a1.output test-A9a1.reqd > var1
diff -w test-A9a.feats test-A9a.feats.reqd > var2
diff -w test-A9a.dims test-A9a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A9a1.reqd";
	cat var1;
	echo "When tested against test-A9a.feats.reqd";
        cat var2;
	echo "When tested against test-A9a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A9a.feats test-A9a.dims test-A9a1.output

echo "Running wordvec.pl --extarget --format i5 --feats test-A9a.feats --dims test-A9a.dims test-A9.bi"

wordvec.pl --extarget --format i5 --feats test-A9a.feats --dims test-A9a.dims test-A9.bi > test-A9a2.output

diff -w test-A9a2.output test-A9a2.reqd > var1
diff -w test-A9a.feats test-A9a.feats.reqd > var2
diff -w test-A9a.dims test-A9a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A9a2.reqd";
        cat var1;
        echo "When tested against test-A9a.feats.reqd";
        cat var2;
        echo "When tested against test-A9a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A9a.feats test-A9a.dims test-A9a2.output

echo "Running wordvec.pl --dense --format i5 --extarget --wordorder nocare --feats test-A9b.feats --dims test-A9b.dims test-A9.bi"

wordvec.pl --dense --format i5 --extarget --wordorder nocare --feats test-A9b.feats --dims test-A9b.dims test-A9.bi > test-A9b1.output

diff test-A9b1.output test-A9b1.reqd > var1
diff -w test-A9b.feats test-A9b.feats.reqd > var2
diff -w test-A9b.dims test-A9b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A9b1.reqd";
        cat var1;
        echo "When tested against test-A9b.feats.reqd";
        cat var2;
        echo "When tested against test-A9b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A9b.feats test-A9b.dims test-A9b1.output

echo "Running wordvec.pl --format i5 --extarget --wordorder nocare --feats test-A9b.feats --dims test-A9b.dims test-A9.bi"

wordvec.pl --format i5 --extarget --wordorder nocare --feats test-A9b.feats --dims test-A9b.dims test-A9.bi > test-A9b2.output

diff -w test-A9b2.output test-A9b2.reqd > var1
diff -w test-A9b.feats test-A9b.feats.reqd > var2
diff -w test-A9b.dims test-A9b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A9b2.reqd";
        cat var1;
        echo "When tested against test-A9b.feats.reqd";
        cat var2;
        echo "When tested against test-A9b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A9b.feats test-A9b.dims test-A9b2.output
