#!/bin/csh
echo "Test A2 - Testing label.pl for condition #Clusters < #Labels";
echo "Running label.pl testA2a.prelabel";
label.pl test-A2a.prelabel > test-A2a.output

sort test-A2a.output > t1
sort test-A2a.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A2a.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A2a.output

echo "Running label.pl testA2b.prelabel";
label.pl test-A2b.prelabel > test-A2b.output

sort test-A2b.output > t1
sort test-A2b.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A2b.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A2b.output

echo "Running label.pl testA2c.prelabel";
label.pl test-A2c.prelabel > test-A2c.output

sort test-A2c.output > t1
sort test-A2c.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A2c.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A2c.output

echo "Running label.pl testA2d.prelabel";
label.pl test-A2d.prelabel > test-A2d.output

sort test-A2d.output > t1
sort test-A2d.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A2d.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A2d.output

echo "Running label.pl testA2e.prelabel";
label.pl test-A2e.prelabel > test-A2e.output

sort test-A2e.output > t1
sort test-A2e.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A2e.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A2e.output
