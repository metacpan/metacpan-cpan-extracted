#!/bin/csh
echo "Test B2 - test-B2.prelabel doesn't contain Sense List starting with //";
echo "Running label.pl test-B2.prelabel";
label.pl test-B2.prelabel >& test-B2.output

sort test-B2.output > t1
sort test-B2.reqd > t2
diff -w t1 t2 > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-B2.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-B2.output

