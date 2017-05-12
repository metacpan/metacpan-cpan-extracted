#!/bin/csh
echo "Test A1 - Testing label.pl for condition #Clusters = #Labels";
echo "Running label.pl testA1a.prelabel";
label.pl test-A1a.prelabel > test-A1a.output

sort test-A1a.output > t1
sort test-A1a.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1a.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1a.output

echo "Running label.pl testA1b.prelabel";
label.pl test-A1b.prelabel > test-A1b.output

sort test-A1b.output > t1
sort test-A1b.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1b.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1b.output

echo "Running label.pl testA1c.prelabel";
label.pl test-A1c.prelabel > test-A1c.output

sort test-A1c.output > t1
sort test-A1c.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1c.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1c.output

echo "Running label.pl testA1d.prelabel";
label.pl test-A1d.prelabel > test-A1d.output

sort test-A1d.output > t1
sort test-A1d.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1d.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1d.output

echo "Running label.pl testA1e.prelabel";
label.pl test-A1e.prelabel > test-A1e.output

sort test-A1e.output > t1
sort test-A1e.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1e.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1e.output

echo "Running label.pl testA1f.prelabel";
label.pl test-A1f.prelabel > test-A1f.output

sort test-A1f.output > t1
sort test-A1f.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1f.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1f.output

echo "Running label.pl testA1g.prelabel";
label.pl test-A1g.prelabel > test-A1g.output

sort test-A1g.output > t1
sort test-A1g.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A1g.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1g.output
