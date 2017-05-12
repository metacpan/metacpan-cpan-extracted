#!/bin/csh

echo "Test A15 for wordvec.pl"
echo "Running wordvec.pl --dense --format f5.2 --feats test-A15a.feats --dims test-A15a.dims test-A15.bi"

wordvec.pl --dense --format f5.2 --feats test-A15a.feats --dims test-A15a.dims test-A15.bi > test-A15a1.output

diff test-A15a1.output test-A15a1.reqd > var1
diff test-A15a.dims test-A15a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A15a1.reqd";
	cat var1;
	echo "When tested against test-A15a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A15a.dims test-A15a1.output

echo "Running wordvec.pl --format f5.2 --feats test-A15a.feats --dims test-A15a.dims test-A15.bi"

wordvec.pl --format f5.2 --feats test-A15a.feats --dims test-A15a.dims test-A15.bi > test-A15a2.output

diff -w test-A15a2.output test-A15a2.reqd > var1
diff -w test-A15a.dims test-A15a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A15a2.reqd";
        cat var1;
        echo "When tested against test-A15a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A15a.dims test-A15a2.output

echo "Running wordvec.pl --dense --format f5.2 --wordorder precede --feats test-A15b.feats --dims test-A15b.dims test-A15.bi"

wordvec.pl --dense --format f5.2 --wordorder precede --feats test-A15b.feats --dims test-A15b.dims test-A15.bi > test-A15b1.output

diff test-A15b1.output test-A15b1.reqd > var1
diff test-A15b.dims test-A15b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A15b1.reqd";
        cat var1;
        echo "When tested against test-A15b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A15b.dims test-A15b1.output

echo "Running wordvec.pl --format f5.2 --wordorder precede --feats test-A15b.feats --dims test-A15b.dims test-A15.bi"

wordvec.pl --format f5.2 --wordorder precede --feats test-A15b.feats --dims test-A15b.dims test-A15.bi > test-A15b2.output

diff -w test-A15b2.output test-A15b2.reqd > var1
diff -w test-A15b.dims test-A15b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A15b2.reqd";
        cat var1;
        echo "When tested against test-A15b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A15b.dims test-A15b2.output

echo "Running wordvec.pl --dense --format f5.2 --wordorder nocare --feats test-A15c.feats --dims test-A15c.dims test-A15.bi"

wordvec.pl --dense --format f5.2 --wordorder nocare --feats test-A15c.feats --dims test-A15c.dims test-A15.bi > test-A15c1.output

diff test-A15c1.output test-A15c1.reqd > var1
diff test-A15c.dims test-A15c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A15c1.reqd";
        cat var1;
        echo "When tested against test-A15c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A15c.dims test-A15c1.output

echo "Running wordvec.pl --format f5.2 --wordorder nocare --feats test-A15c.feats --dims test-A15c.dims test-A15.bi"

wordvec.pl --format f5.2 --wordorder nocare --feats test-A15c.feats --dims test-A15c.dims test-A15.bi > test-A15c2.output

diff -w test-A15c2.output test-A15c2.reqd > var1
diff -w test-A15c.dims test-A15c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A15c2.reqd";
        cat var1;
        echo "When tested against test-A15c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A15c.dims test-A15c2.output

