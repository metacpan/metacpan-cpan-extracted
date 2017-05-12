#!/bin/csh
echo "Test A3 - Testing label.pl for condition #Clusters > #Labels";
echo "Running label.pl testA3a.prelabel";
label.pl test-A3a.prelabel > test-A3a.output

sort test-A3a.output > t1
sort test-A3a.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3a.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3a.output

echo "Running label.pl testA3b.prelabel";
label.pl test-A3b.prelabel > test-A3b.output

sort test-A3b.output > t1
sort test-A3b.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3b.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3b.output

echo "Running label.pl testA3c.prelabel";
label.pl test-A3c.prelabel > test-A3c.output

sort test-A3c.output > t1
sort test-A3c.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3c.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3c.output

echo "Running label.pl testA3d.prelabel";
label.pl test-A3d.prelabel > test-A3d.output

sort test-A3d.output > t1
sort test-A3d.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3d.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3d.output

echo "Running label.pl testA3e.prelabel";
label.pl test-A3e.prelabel > test-A3e.output

sort test-A3e.output > t1
sort test-A3e.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3e.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3e.output

echo "Running label.pl testA3f.prelabel";
label.pl test-A3f.prelabel > test-A3f.output

sort test-A3f.output > t1
sort test-A3f.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3f.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3f.output

echo "Running label.pl testA3g.prelabel";
label.pl test-A3g.prelabel > test-A3g.output

sort test-A3g.output > t1
sort test-A3g.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3g.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3g.output

echo "Running label.pl testA3h.prelabel";
label.pl test-A3h.prelabel > test-A3h.output

sort test-A3h.output > t1
sort test-A3h.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A3h.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3h.output
