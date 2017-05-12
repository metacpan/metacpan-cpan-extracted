#!/bin/csh

echo "Test A5 for wordvec.pl"
echo "Running wordvec.pl --dense --format f5.2 --feats test-A5a.feats --dims test-A5a.dims test-A5.bi"

wordvec.pl --dense --format f5.2 --feats test-A5a.feats --dims test-A5a.dims test-A5.bi > test-A5a1.output

diff test-A5a1.output test-A5a1.reqd > var1
diff test-A5a.feats test-A5a.feats.reqd > var2
diff test-A5a.dims test-A5a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A5a1.reqd";
	cat var1;
	echo "When tested against test-A5a.feats.reqd";
        cat var2;
	echo "When tested against test-A5a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A5a.feats test-A5a.dims test-A5a1.output

echo "Running wordvec.pl --format f5.2 --feats test-A5a.feats --dims test-A5a.dims test-A5.bi"

wordvec.pl --format f5.2 --feats test-A5a.feats --dims test-A5a.dims test-A5.bi > test-A5a2.output

diff -w test-A5a2.output test-A5a2.reqd > var1
diff -w test-A5a.feats test-A5a.feats.reqd > var2
diff -w test-A5a.dims test-A5a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5a2.reqd";
        cat var1;
        echo "When tested against test-A5a.feats.reqd";
        cat var2;
        echo "When tested against test-A5a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A5a.feats test-A5a.dims test-A5a2.output

echo "Running wordvec.pl --dense --format f5.2 --wordorder precede --feats test-A5b.feats --dims test-A5b.dims test-A5.bi"

wordvec.pl --dense --format f5.2 --wordorder precede --feats test-A5b.feats --dims test-A5b.dims test-A5.bi > test-A5b1.output

diff test-A5b1.output test-A5b1.reqd > var1
diff test-A5b.feats test-A5b.feats.reqd > var2
diff test-A5b.dims test-A5b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5b1.reqd";
        cat var1;
        echo "When tested against test-A5b.feats.reqd";
        cat var2;
        echo "When tested against test-A5b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A5b.feats test-A5b.dims test-A5b1.output

echo "Running wordvec.pl --format f5.2 --wordorder precede --feats test-A5b.feats --dims test-A5b.dims test-A5.bi"

wordvec.pl --format f5.2 --wordorder precede --feats test-A5b.feats --dims test-A5b.dims test-A5.bi > test-A5b2.output

diff -w test-A5b2.output test-A5b2.reqd > var1
diff -w test-A5b.feats test-A5b.feats.reqd > var2
diff -w test-A5b.dims test-A5b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5b2.reqd";
        cat var1;
        echo "When tested against test-A5b.feats.reqd";
        cat var2;
        echo "When tested against test-A5b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A5b.feats test-A5b.dims test-A5b2.output

echo "Running wordvec.pl --dense --format f5.2 --wordorder nocare --feats test-A5c.feats --dims test-A5c.dims test-A5.bi"

wordvec.pl --dense --format f5.2 --wordorder nocare --feats test-A5c.feats --dims test-A5c.dims test-A5.bi > test-A5c1.output

diff test-A5c1.output test-A5c1.reqd > var1
diff test-A5c.feats test-A5c.feats.reqd > var2
diff test-A5c.dims test-A5c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5c1.reqd";
        cat var1;
	echo "When tested against test-A5c.feats.reqd";
        cat var2;
        echo "When tested against test-A5c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A5c.feats test-A5c.dims test-A5c1.output

echo "Running wordvec.pl --format f5.2 --wordorder nocare --feats test-A5c.feats --dims test-A5c.dims test-A5.bi"

wordvec.pl --format f5.2 --wordorder nocare --feats test-A5c.feats --dims test-A5c.dims test-A5.bi > test-A5c2.output

diff -w test-A5c2.output test-A5c2.reqd > var1
diff -w test-A5c.feats test-A5c.feats.reqd > var2
diff -w test-A5c.dims test-A5c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A5c2.reqd";
        cat var1;
        echo "When tested against test-A5c.feats.reqd";
        cat var2;
        echo "When tested against test-A5c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A5c.feats test-A5c.dims test-A5c2.output
