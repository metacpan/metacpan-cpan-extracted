#!/bin/csh

echo "Test A17 for wordvec.pl"
echo "Running wordvec.pl --dense --format f4.1 --feats test-A17a.feats --dims test-A17a.dims test-A17.bi"

wordvec.pl --dense --format f4.1 --feats test-A17a.feats --dims test-A17a.dims test-A17.bi > test-A17a1.output

diff test-A17a1.output test-A17a1.reqd > var1
diff test-A17a.dims test-A17a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A17a1.reqd";
	cat var1;
	echo "When tested against test-A17a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A17a.dims test-A17a1.output

echo "Running wordvec.pl --format f4.1 --feats test-A17a.feats --dims test-A17a.dims test-A17.bi"

wordvec.pl --format f4.1 --feats test-A17a.feats --dims test-A17a.dims test-A17.bi > test-A17a2.output

diff -w test-A17a2.output test-A17a2.reqd > var1
diff -w test-A17a.dims test-A17a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A17a2.reqd";
        cat var1;
        echo "When tested against test-A17a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A17a.dims test-A17a2.output

echo "Running wordvec.pl --dense --format f4.1 --wordorder precede --feats test-A17b.feats --dims test-A17b.dims test-A17.bi"

wordvec.pl --dense --format f4.1 --wordorder precede --feats test-A17b.feats --dims test-A17b.dims test-A17.bi > test-A17b1.output

diff test-A17b1.output test-A17b1.reqd > var1
diff test-A17b.dims test-A17b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A17b1.reqd";
        cat var1;
        echo "When tested against test-A17b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A17b.dims test-A17b1.output

echo "Running wordvec.pl --format f4.1 --wordorder precede --feats test-A17b.feats --dims test-A17b.dims test-A17.bi"

wordvec.pl --format f4.1 --wordorder precede --feats test-A17b.feats --dims test-A17b.dims test-A17.bi > test-A17b2.output

diff -w test-A17b2.output test-A17b2.reqd > var1
diff -w test-A17b.dims test-A17b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A17b2.reqd";
        cat var1;
        echo "When tested against test-A17b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A17b.dims test-A17b2.output

echo "Running wordvec.pl --dense --format f4.1 --wordorder nocare --feats test-A17c.feats --dims test-A17c.dims test-A17.bi"

wordvec.pl --dense --format f4.1 --wordorder nocare --feats test-A17c.feats --dims test-A17c.dims test-A17.bi > test-A17c1.output

diff test-A17c1.output test-A17c1.reqd > var1
diff test-A17c.dims test-A17c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A17c1.reqd";
        cat var1;
        echo "When tested against test-A17c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A17c.dims test-A17c1.output

echo "Running wordvec.pl --format f4.1 --wordorder nocare --feats test-A17c.feats --dims test-A17c.dims test-A17.bi"

wordvec.pl --format f4.1 --wordorder nocare --feats test-A17c.feats --dims test-A17c.dims test-A17.bi > test-A17c2.output

diff -w test-A17c2.output test-A17c2.reqd > var1
diff -w test-A17c.dims test-A17c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A17c2.reqd";
        cat var1;
        echo "When tested against test-A17c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A17c.dims test-A17c2.output
