#!/bin/csh

echo "Test A19 for wordvec.pl"
echo "Running wordvec.pl --dense --extarget --format i5 --feats test-A19a.feats --dims test-A19a.dims test-A19.bi"

wordvec.pl --dense --extarget --format i5 --feats test-A19a.feats --dims test-A19a.dims test-A19.bi > test-A19a1.output

diff test-A19a1.output test-A19a1.reqd > var1
diff -w test-A19a.dims test-A19a.dims.reqd > var3

if(-z var1 && -z var3) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A19a1.reqd";
	cat var1;
	echo "When tested against test-A19a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A19a.dims test-A19a1.output

echo "Running wordvec.pl --extarget --format i5 --feats test-A19a.feats --dims test-A19a.dims test-A19.bi"

wordvec.pl --extarget --format i5 --feats test-A19a.feats --dims test-A19a.dims test-A19.bi > test-A19a2.output

diff -w test-A19a2.output test-A19a2.reqd > var1
diff -w test-A19a.dims test-A19a.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A19a2.reqd";
        cat var1;
        echo "When tested against test-A19a.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A19a.dims test-A19a2.output

echo "Running wordvec.pl --dense --format i5 --extarget --wordorder nocare --feats test-A19b.feats --dims test-A19b.dims test-A19.bi"

wordvec.pl --dense --format i5 --extarget --wordorder nocare --feats test-A19b.feats --dims test-A19b.dims test-A19.bi > test-A19b1.output

diff test-A19b1.output test-A19b1.reqd > var1
diff -w test-A19b.dims test-A19b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A19b1.reqd";
        cat var1;
        echo "When tested against test-A19b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A19b.dims test-A19b1.output

echo "Running wordvec.pl --format i5 --extarget --wordorder nocare --feats test-A19b.feats --dims test-A19b.dims test-A19.bi"

wordvec.pl --format i5 --extarget --wordorder nocare --feats test-A19b.feats --dims test-A19b.dims test-A19.bi > test-A19b2.output

diff -w test-A19b2.output test-A19b2.reqd > var1
diff -w test-A19b.dims test-A19b.dims.reqd > var3

if(-z var1 && -z var3) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A19b2.reqd";
        cat var1;
        echo "When tested against test-A19b.dims.reqd";
        cat var3;
endif

/bin/rm -f var1 var3 test-A19b.dims test-A19b2.output
