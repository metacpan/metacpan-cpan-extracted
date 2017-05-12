#!/bin/csh

echo "Test A6 for wordvec.pl"
echo "Running wordvec.pl --dense --format f6.3 --feats test-A6a.feats --dims test-A6a.dims test-A6.bi"

wordvec.pl --dense --format f6.3 --feats test-A6a.feats --dims test-A6a.dims test-A6.bi > test-A6a1.output

diff test-A6a1.output test-A6a1.reqd > var1

diff test-A6a.feats test-A6a.feats.reqd > var2

diff test-A6a.dims test-A6a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A6a1.reqd";
	cat var1;
	echo "When tested against test-A6a.feats.reqd";
        cat var2;
	echo "When tested against test-A6a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A6a.feats test-A6a.dims test-A6a1.output

echo "Running wordvec.pl --format f6.3 --feats test-A6a.feats --dims test-A6a.dims test-A6.bi"

wordvec.pl --format f6.3 --feats test-A6a.feats --dims test-A6a.dims test-A6.bi > test-A6a2.output

diff -w test-A6a2.output test-A6a2.reqd > var1

diff test-A6a.feats test-A6a.feats.reqd > var2

diff test-A6a.dims test-A6a.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A6a2.reqd";
        cat var1;
        echo "When tested against test-A6a.feats.reqd";
        cat var2;
        echo "When tested against test-A6a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A6a.feats test-A6a.dims test-A6a2.output

echo "Running wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A6b.feats --dims test-A6b.dims test-A6.bi"

wordvec.pl --dense --format f6.3 --wordorder precede --feats test-A6b.feats --dims test-A6b.dims test-A6.bi > test-A6b1.output

diff test-A6b1.output test-A6b1.reqd > var1

diff test-A6b.feats test-A6b.feats.reqd > var2

diff test-A6b.dims test-A6b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A6b1.reqd";
        cat var1;
        echo "When tested against test-A6b.feats.reqd";
        cat var2;
        echo "When tested against test-A6b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A6b.feats test-A6b.dims test-A6b1.output

echo "Running wordvec.pl --format f6.3 --wordorder precede --feats test-A6b.feats --dims test-A6b.dims test-A6.bi"

wordvec.pl --format f6.3 --wordorder precede --feats test-A6b.feats --dims test-A6b.dims test-A6.bi > test-A6b2.output

diff -w test-A6b2.output test-A6b2.reqd > var1

diff test-A6b.feats test-A6b.feats.reqd > var2

diff test-A6b.dims test-A6b.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A6b2.reqd";
        cat var1;
        echo "When tested against test-A6b.feats.reqd";
        cat var2;
        echo "When tested against test-A6b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A6b.feats test-A6b.dims test-A6b2.output

echo "Running wordvec.pl --dense --format f6.3 --wordorder nocare --feats test-A6c.feats --dims test-A6c.dims test-A6.bi"

wordvec.pl --dense --format f6.3 --wordorder nocare --feats test-A6c.feats --dims test-A6c.dims test-A6.bi > test-A6c1.output

diff test-A6c1.output test-A6c1.reqd > var1

diff test-A6c.feats test-A6c.feats.reqd > var2

diff test-A6c.dims test-A6c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A6c1.reqd";
        cat var1;
	echo "When tested against test-A6c.feats.reqd";
        cat var2;
        echo "When tested against test-A6c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A6c.feats test-A6c.dims test-A6c1.output

echo "Running wordvec.pl --format f6.3 --wordorder nocare --feats test-A6c.feats --dims test-A6c.dims test-A6.bi"

wordvec.pl --format f6.3 --wordorder nocare --feats test-A6c.feats --dims test-A6c.dims test-A6.bi > test-A6c2.output

diff -w test-A6c2.output test-A6c2.reqd > var1

diff test-A6c.feats test-A6c.feats.reqd > var2

diff test-A6c.dims test-A6c.dims.reqd > var3

if(-z var1 && -z var2 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A6c2.reqd";
        cat var1;
        echo "When tested against test-A6c.feats.reqd";
        cat var2;
        echo "When tested against test-A6c.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var2 var3 test-A6c.feats test-A6c.dims test-A6c2.output

