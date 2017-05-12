#!/bin/csh

echo "Test A16 for wordvec.pl"
echo "Running wordvec.pl --dense --format f6.3 --feats test-A16a.feats --dims test-A16a.dims test-A16.bi"

wordvec.pl --dense --format f6.3 --feats test-A16a.feats --dims test-A16a.dims test-A16.bi > test-A16a1.output

diff test-A16a1.output test-A16a1.reqd > var1
diff test-A16a.dims test-A16a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A16a1.reqd";
	cat var1;
	echo "When tested against test-A16a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A16a.dims test-A16a1.output

echo "Running wordvec.pl --format f6.3 --feats test-A16a.feats --dims test-A16a.dims test-A16.bi"

wordvec.pl --format f6.3 --feats test-A16a.feats --dims test-A16a.dims test-A16.bi > test-A16a2.output

diff -w test-A16a2.output test-A16a2.reqd > var1
diff test-A16a.dims test-A16a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A16a2.reqd";
        cat var1;
        echo "When tested against test-A16a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A16a.dims test-A16a2.output

echo "Running wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A16b.feats --dims test-A16b.dims test-A16.bi"

wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A16b.feats --dims test-A16b.dims test-A16.bi > test-A16b1.output

diff test-A16b1.output test-A16b1.reqd > var1
diff test-A16b.dims test-A16b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A16b1.reqd";
        cat var1;
        echo "When tested against test-A16b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A16b.dims test-A16b1.output

echo "Running wordvec.pl --format f6.3 --wordorder precede --feats test-A16b.feats --dims test-A16b.dims test-A16.bi"

wordvec.pl --format f6.3 --wordorder precede --feats test-A16b.feats --dims test-A16b.dims test-A16.bi > test-A16b2.output

diff -w test-A16b2.output test-A16b2.reqd > var1
diff test-A16b.dims test-A16b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A16b2.reqd";
        cat var1;
        echo "When tested against test-A16b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A16b.dims test-A16b2.output

echo "Running wordvec.pl --dense --format f6.3 --wordorder nocare --feats test-A16c.feats --dims test-A16c.dims test-A16.bi"

wordvec.pl --dense --format f6.3 --wordorder nocare --feats test-A16c.feats --dims test-A16c.dims test-A16.bi > test-A16c1.output

diff test-A16c1.output test-A16c1.reqd > var1
diff test-A16c.dims test-A16c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A16c1.reqd";
        cat var1;
        echo "When tested against test-A16c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A16c.dims test-A16c1.output

echo "Running wordvec.pl --format f6.3 --wordorder nocare --feats test-A16c.feats --dims test-A16c.dims test-A16.bi"

wordvec.pl --format f6.3 --wordorder nocare --feats test-A16c.feats --dims test-A16c.dims test-A16.bi > test-A16c2.output

diff -w test-A16c2.output test-A16c2.reqd > var1
diff test-A16c.dims test-A16c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A16c2.reqd";
        cat var1;
        echo "When tested against test-A16c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A16c.dims test-A16c2.output
