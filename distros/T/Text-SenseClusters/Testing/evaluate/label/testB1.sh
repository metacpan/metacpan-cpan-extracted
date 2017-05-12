#!/bin/csh
echo "Test B1 - test-B1.prelabel doesn't start with #unclustered instances";
echo "Running label.pl test-B1.prelabel";
label.pl test-B1.prelabel >& test-B1.output

sort test-B1.output > t1
sort test-B1.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-B1.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-B1.output

