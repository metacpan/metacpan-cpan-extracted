#!/bin/csh

echo "Test A3 for wordvec.pl"
echo "Running wordvec.pl --dense --format f6.3 --feats test-A3a.feats --dims test-A3a.dims test-A3.bi"

wordvec.pl --dense --format f6.3 --feats test-A3a.feats --dims test-A3a.dims test-A3.bi > test-A3a1.output

diff test-A3a1.output test-A3a1.reqd > var1
diff test-A3a.feats test-A3a.feats.reqd > var2
diff test-A3a.dims test-A3a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3a1.reqd";
	cat var1;
	echo "When tested against test-A3a.feats.reqd";
        cat var2;
	echo "When tested against test-A3a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A3a.feats test-A3a.dims test-A3a1.output

echo "Running wordvec.pl --format f6.3 --feats test-A3a.feats --dims test-A3a.dims test-A3.bi"

wordvec.pl --format f6.3 --feats test-A3a.feats --dims test-A3a.dims test-A3.bi > test-A3a2.output

diff -w test-A3a2.output test-A3a2.reqd > var1
diff -w test-A3a.feats test-A3a.feats.reqd > var2
diff -w test-A3a.dims test-A3a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3a2.reqd";
        cat var1;
        echo "When tested against test-A3a.feats.reqd";
        cat var2;
        echo "When tested against test-A3a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A3a.feats test-A3a.dims test-A3a2.output

echo "Running wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A3b.feats --dims test-A3b.dims test-A3.bi"

wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A3b.feats --dims test-A3b.dims test-A3.bi > test-A3b1.output

diff test-A3b1.output test-A3b1.reqd > var1
diff test-A3b.feats test-A3b.feats.reqd > var2
diff test-A3b.dims test-A3b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3b1.reqd";
        cat var1;
        echo "When tested against test-A3b.feats.reqd";
        cat var2;
        echo "When tested against test-A3b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A3b.feats test-A3b.dims test-A3b1.output

echo "Running wordvec.pl --format f6.3 --wordorder precede --feats test-A3b.feats --dims test-A3b.dims test-A3.bi"

wordvec.pl --format f6.3 --wordorder precede --feats test-A3b.feats --dims test-A3b.dims test-A3.bi > test-A3b2.output

diff -w test-A3b2.output test-A3b2.reqd > var1
diff -w test-A3b.feats test-A3b.feats.reqd > var2
diff -w test-A3b.dims test-A3b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3b2.reqd";
        cat var1;
        echo "When tested against test-A3b.feats.reqd";
        cat var2;
        echo "When tested against test-A3b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A3b.feats test-A3b.dims test-A3b2.output

echo "Running wordvec.pl  --dense --format f6.3 --wordorder nocare --feats test-A3c.feats --dims test-A3c.dims test-A3.bi"

wordvec.pl --dense --format f6.3 --wordorder nocare --feats test-A3c.feats --dims test-A3c.dims test-A3.bi > test-A3c1.output

diff test-A3c1.output test-A3c1.reqd > var1
diff test-A3c.feats test-A3c.feats.reqd > var2
diff test-A3c.dims test-A3c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3c1.reqd";
        cat var1;
	echo "When tested against test-A3c.feats.reqd";
        cat var2;
        echo "When tested against test-A3c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A3c.feats test-A3c.dims test-A3c1.output

echo "Running wordvec.pl  --format f6.3 --wordorder nocare --feats test-A3c.feats --dims test-A3c.dims test-A3.bi"

wordvec.pl --format f6.3 --wordorder nocare --feats test-A3c.feats --dims test-A3c.dims test-A3.bi > test-A3c2.output

diff -w test-A3c2.output test-A3c2.reqd > var1
diff -w test-A3c.feats test-A3c.feats.reqd > var2
diff -w test-A3c.dims test-A3c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3c2.reqd";
        cat var1;
        echo "When tested against test-A3c.feats.reqd";
        cat var2;
        echo "When tested against test-A3c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A3c.feats test-A3c.dims test-A3c2.output
