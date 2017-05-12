#!/bin/csh 
echo "TEST A6";
echo "Running report.pl test-A6.map test-A6.matrix ";

report.pl test-A6.map test-A6.matrix > test-A6.output

diff -w test-A6.output test-A6.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A6.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A6.output 
