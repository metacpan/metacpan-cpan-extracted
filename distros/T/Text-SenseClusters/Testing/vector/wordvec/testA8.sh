#!/bin/csh

echo "Test A8 for wordvec.pl"
echo "Running wordvec.pl --dense --binary --feats test-A8a.feats --dims test-A8a.dims test-A8.bi"

wordvec.pl --dense --binary --feats test-A8a.feats --dims test-A8a.dims test-A8.bi > test-A8a1.output

diff test-A8a1.output test-A8a1.reqd > var1
diff test-A8a.feats test-A8a.feats.reqd > var2
diff test-A8a.dims test-A8a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A8a1.reqd";
	cat var1;
	echo "When tested against test-A8a.feats.reqd";
        cat var2;
	echo "When tested against test-A8a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A8a.feats test-A8a.dims test-A8a1.output

echo "Running wordvec.pl --binary --feats test-A8a.feats --dims test-A8a.dims test-A8.bi"

wordvec.pl --binary --feats test-A8a.feats --dims test-A8a.dims test-A8.bi > test-A8a2.output

diff -w test-A8a2.output test-A8a2.reqd > var1
diff -w test-A8a.feats test-A8a.feats.reqd > var2
diff -w test-A8a.dims test-A8a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8a2.reqd";
        cat var1;
        echo "When tested against test-A8a.feats.reqd";
        cat var2;
        echo "When tested against test-A8a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A8a.feats test-A8a.dims test-A8a2.output


echo "Running wordvec.pl --dense --binary --wordorder precede --feats test-A8b.feats --dims test-A8b.dims test-A8.bi"

wordvec.pl --dense --binary --wordorder precede --feats test-A8b.feats --dims test-A8b.dims test-A8.bi > test-A8b1.output

diff test-A8b1.output test-A8b1.reqd > var1
diff test-A8b.feats test-A8b.feats.reqd > var2
diff test-A8b.dims test-A8b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8b1.reqd";
        cat var1;
        echo "When tested against test-A8b.feats.reqd";
        cat var2;
        echo "When tested against test-A8b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A8b.feats test-A8b.dims test-A8b1.output

echo "Running wordvec.pl --binary --wordorder precede --feats test-A8b.feats --dims test-A8b.dims test-A8.bi"

wordvec.pl --binary --wordorder precede --feats test-A8b.feats --dims test-A8b.dims test-A8.bi > test-A8b2.output

diff -w test-A8b2.output test-A8b2.reqd > var1
diff -w test-A8b.feats test-A8b.feats.reqd > var2
diff -w test-A8b.dims test-A8b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8b2.reqd";
        cat var1;
        echo "When tested against test-A8b.feats.reqd";
        cat var2;
        echo "When tested against test-A8b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A8b.feats test-A8b.dims test-A8b2.output


echo "Running wordvec.pl --dense --binary --wordorder nocare --feats test-A8c.feats --dims test-A8c.dims test-A8.bi"

wordvec.pl --dense --binary --wordorder nocare --feats test-A8c.feats --dims test-A8c.dims test-A8.bi > test-A8c1.output

diff test-A8c1.output test-A8c1.reqd > var1
diff test-A8c.feats test-A8c.feats.reqd > var2
diff test-A8c.dims test-A8c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8c1.reqd";
        cat var1;
	echo "When tested against test-A8c.feats.reqd";
        cat var2;
        echo "When tested against test-A8c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A8c.feats test-A8c.dims test-A8c1.output

echo "Running wordvec.pl --binary --wordorder nocare --feats test-A8c.feats --dims test-A8c.dims test-A8.bi"

wordvec.pl --binary --wordorder nocare --feats test-A8c.feats --dims test-A8c.dims test-A8.bi > test-A8c2.output

diff -w test-A8c2.output test-A8c2.reqd > var1
diff -w test-A8c.feats test-A8c.feats.reqd > var2
diff -w test-A8c.dims test-A8c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8c2.reqd";
        cat var1;
        echo "When tested against test-A8c.feats.reqd";
        cat var2;
        echo "When tested against test-A8c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A8c.feats test-A8c.dims test-A8c2.output
