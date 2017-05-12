#!/bin/csh

echo "Test A7 for wordvec.pl"
echo "Running wordvec.pl --dense --format f4.1 --feats test-A7a.feats --dims test-A7a.dims test-A7.bi"

wordvec.pl --dense --format f4.1 --feats test-A7a.feats --dims test-A7a.dims test-A7.bi > test-A7a1.output

diff test-A7a1.output test-A7a1.reqd > var1
diff test-A7a.feats test-A7a.feats.reqd > var2
diff test-A7a.dims test-A7a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A7a1.reqd";
	cat var1;
	echo "When tested against test-A7a.feats.reqd";
        cat var2;
	echo "When tested against test-A7a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7a.feats test-A7a.dims test-A7a1.output

echo "Running wordvec.pl --format f4.1 --feats test-A7a.feats --dims test-A7a.dims test-A7.bi"

wordvec.pl --format f4.1 --feats test-A7a.feats --dims test-A7a.dims test-A7.bi > test-A7a2.output

diff -w test-A7a2.output test-A7a2.reqd > var1
diff -w test-A7a.feats test-A7a.feats.reqd > var2
diff -w test-A7a.dims test-A7a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A7a2.reqd";
        cat var1;
        echo "When tested against test-A7a.feats.reqd";
        cat var2;
        echo "When tested against test-A7a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7a.feats test-A7a.dims test-A7a2.output

echo "Running wordvec.pl --dense --format f4.1 --wordorder precede --feats test-A7b.feats --dims test-A7b.dims test-A7.bi"

wordvec.pl --dense --format f4.1 --wordorder precede --feats test-A7b.feats --dims test-A7b.dims test-A7.bi > test-A7b1.output

diff test-A7b1.output test-A7b1.reqd > var1
diff test-A7b.feats test-A7b.feats.reqd > var2
diff test-A7b.dims test-A7b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A7b1.reqd";
        cat var1;
        echo "When tested against test-A7b.feats.reqd";
        cat var2;
        echo "When tested against test-A7b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7b.feats test-A7b.dims test-A7b1.output

echo "Running wordvec.pl --format f4.1 --wordorder precede --feats test-A7b.feats --dims test-A7b.dims test-A7.bi"

wordvec.pl --format f4.1 --wordorder precede --feats test-A7b.feats --dims test-A7b.dims test-A7.bi > test-A7b2.output

diff -w test-A7b2.output test-A7b2.reqd > var1
diff -w test-A7b.feats test-A7b.feats.reqd > var2
diff -w test-A7b.dims test-A7b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A7b2.reqd";
        cat var1;
        echo "When tested against test-A7b.feats.reqd";
        cat var2;
        echo "When tested against test-A7b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7b.feats test-A7b.dims test-A7b2.output

echo "Running wordvec.pl --dense --format f4.1 --wordorder nocare --feats test-A7c.feats --dims test-A7c.dims test-A7.bi"

wordvec.pl --dense --format f4.1 --wordorder nocare --feats test-A7c.feats --dims test-A7c.dims test-A7.bi > test-A7c1.output

diff test-A7c1.output test-A7c1.reqd > var1
diff test-A7c.feats test-A7c.feats.reqd > var2
diff test-A7c.dims test-A7c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A7c1.reqd";
        cat var1;
	echo "When tested against test-A7c.feats.reqd";
        cat var2;
        echo "When tested against test-A7c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7c.feats test-A7c.dims test-A7c1.output

echo "Running wordvec.pl --format f4.1 --wordorder nocare --feats test-A7c.feats --dims test-A7c.dims test-A7.bi"

wordvec.pl --format f4.1 --wordorder nocare --feats test-A7c.feats --dims test-A7c.dims test-A7.bi > test-A7c2.output

diff -w test-A7c2.output test-A7c2.reqd > var1
diff -w test-A7c.feats test-A7c.feats.reqd > var2
diff -w test-A7c.dims test-A7c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A7c2.reqd";
        cat var1;
        echo "When tested against test-A7c.feats.reqd";
        cat var2;
        echo "When tested against test-A7c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A7c.feats test-A7c.dims test-A7c2.output
