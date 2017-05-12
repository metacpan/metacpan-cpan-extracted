#!/bin/csh

echo "Test A20 for wordvec.pl"
echo "Running wordvec.pl --dense --extarget --format i3 --feats test-A20a.feats --dims test-A20a.dims test-A20.bi"

wordvec.pl --dense --extarget --format i3 --feats test-A20a.feats --dims test-A20a.dims test-A20.bi > test-A20a1.output

diff test-A20a1.output test-A20a1.reqd > var1
diff -w test-A20a.dims test-A20a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A20a1.reqd";
	cat var1;
	echo "When tested against test-A20a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A20a.dims test-A20a1.output

echo "Running wordvec.pl --extarget --format i3 --feats test-A20a.feats --dims test-A20a.dims test-A20.bi"

wordvec.pl --extarget --format i3 --feats test-A20a.feats --dims test-A20a.dims test-A20.bi > test-A20a2.output

diff -w test-A20a2.output test-A20a2.reqd > var1
diff -w test-A20a.dims test-A20a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A20a2.reqd";
        cat var1;
        echo "When tested against test-A20a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A20a.dims test-A20a2.output

echo "Running wordvec.pl --wordorder precede --dense --extarget --format i3 --feats test-A20b.feats --dims test-A20b.dims test-A20.bi"

wordvec.pl --wordorder precede --dense --extarget --format i3 --feats test-A20b.feats --dims test-A20b.dims test-A20.bi > test-A20b1.output

diff test-A20b1.output test-A20b1.reqd > var1
diff -w test-A20b.dims test-A20b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A20b1.reqd";
        cat var1;
        echo "When tested against test-A20b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A20b.dims test-A20b1.output

echo "Running wordvec.pl --format i3 --extarget --wordorder precede --feats test-A20b.feats --dims test-A20b.dims test-A20.bi"

wordvec.pl --format i3 --extarget --wordorder precede --feats test-A20b.feats --dims test-A20b.dims test-A20.bi > test-A20b2.output

diff -w test-A20b2.output test-A20b2.reqd > var1
diff -w test-A20b.dims test-A20b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A20b2.reqd";
        cat var1;
        echo "When tested against test-A20b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A20b.dims test-A20b2.output

echo "Running wordvec.pl --dense --format i3 --extarget --wordorder nocare --feats test-A20c.feats --dims test-A20c.dims test-A20.bi"

wordvec.pl --dense --format i3 --extarget --wordorder nocare --feats test-A20c.feats --dims test-A20c.dims test-A20.bi > test-A20c1.output

diff test-A20c1.output test-A20c1.reqd > var1
diff -w test-A20c.dims test-A20c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A20c1.reqd";
        cat var1;
        echo "When tested against test-A20c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A20c.dims test-A20c1.output

echo "Running wordvec.pl --format i3 --extarget --wordorder nocare --feats test-A20c.feats --dims test-A20c.dims test-A20.bi"

wordvec.pl --format i3 --extarget --wordorder nocare --feats test-A20c.feats --dims test-A20c.dims test-A20.bi > test-A20c2.output

diff -w test-A20c2.output test-A20c2.reqd > var1
diff -w test-A20c.dims test-A20c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A20c2.reqd";
        cat var1;
        echo "When tested against test-A20c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A20c.dims test-A20c2.output
