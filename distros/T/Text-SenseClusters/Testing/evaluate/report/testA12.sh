#!/bin/csh 
echo "TEST A12";
echo "Running report.pl test-A12.map test-A12.matrix ";

report.pl test-A12.map test-A12.matrix > test-A12.output

diff -w test-A12.output test-A12.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A12.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A12.output 
