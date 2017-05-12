#!/bin/csh

echo "Test A18 for wordvec.pl"
echo "Running wordvec.pl --dense --binary --feats test-A18a.feats --dims test-A18a.dims test-A18.bi"

wordvec.pl --dense --binary --feats test-A18a.feats --dims test-A18a.dims test-A18.bi > test-A18a1.output

diff test-A18a1.output test-A18a1.reqd > var1
diff test-A18a.dims test-A18a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A18a1.reqd";
	cat var1;
	echo "When tested against test-A18a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A18a.dims test-A18a1.output

echo "Running wordvec.pl --binary --feats test-A18a.feats --dims test-A18a.dims test-A18.bi"

wordvec.pl --binary --feats test-A18a.feats --dims test-A18a.dims test-A18.bi > test-A18a2.output

diff -w test-A18a2.output test-A18a2.reqd > var1
diff -w test-A18a.dims test-A18a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A18a2.reqd";
        cat var1;
        echo "When tested against test-A18a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A18a.dims test-A18a2.output


echo "Running wordvec.pl --dense --binary --wordorder precede --feats test-A18b.feats --dims test-A18b.dims test-A18.bi"

wordvec.pl --dense --binary --wordorder precede --feats test-A18b.feats --dims test-A18b.dims test-A18.bi > test-A18b1.output

diff test-A18b1.output test-A18b1.reqd > var1
diff test-A18b.dims test-A18b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A18b1.reqd";
        cat var1;
        echo "When tested against test-A18b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A18b.dims test-A18b1.output

echo "Running wordvec.pl --binary --wordorder precede --feats test-A18b.feats --dims test-A18b.dims test-A18.bi"

wordvec.pl --binary --wordorder precede --feats test-A18b.feats --dims test-A18b.dims test-A18.bi > test-A18b2.output

diff -w test-A18b2.output test-A18b2.reqd > var1
diff -w test-A18b.dims test-A18b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A18b2.reqd";
        cat var1;
        echo "When tested against test-A18b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A18b.dims test-A18b2.output


echo "Running wordvec.pl --dense --binary --wordorder nocare --feats test-A18c.feats --dims test-A18c.dims test-A18.bi"

wordvec.pl --dense --binary --wordorder nocare --feats test-A18c.feats --dims test-A18c.dims test-A18.bi > test-A18c1.output

diff test-A18c1.output test-A18c1.reqd > var1
diff test-A18c.dims test-A18c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A18c1.reqd";
        cat var1;
        echo "When tested against test-A18c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A18c.dims test-A18c1.output

echo "Running wordvec.pl --binary --wordorder nocare --feats test-A18c.feats --dims test-A18c.dims test-A18.bi"

wordvec.pl --binary --wordorder nocare --feats test-A18c.feats --dims test-A18c.dims test-A18.bi > test-A18c2.output

diff -w test-A18c2.output test-A18c2.reqd > var1
diff -w test-A18c.dims test-A18c.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A18c2.reqd";
        cat var1;
        echo "When tested against test-A18c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A18c.dims test-A18c2.output
