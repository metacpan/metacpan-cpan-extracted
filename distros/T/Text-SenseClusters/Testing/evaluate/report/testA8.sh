#!/bin/csh 
echo "TEST A8";
echo "Running report.pl test-A8.map test-A8.matrix ";

report.pl test-A8.map test-A8.matrix > test-A8.output

diff -w test-A8.output test-A8.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A8.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A8.output 
