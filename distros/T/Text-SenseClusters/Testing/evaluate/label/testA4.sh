#!/bin/csh
echo "Test A4 - Testing label.pl for condition #Clusters=25 and #Labels=25";
echo "Running label.pl test-A4.prelabel";
label.pl test-A4.prelabel > test-A4.output

diff -w test-A4.output test-A4.reqd > variance

if(-z variance) then
        echo "STATUS :  OK Test Results Match.....";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against test-A4.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A4.output
