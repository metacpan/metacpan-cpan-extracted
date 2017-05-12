#!/bin/csh 
echo "TEST A10";
echo "Running report.pl test-A10.map test-A10.matrix ";

report.pl test-A10.map test-A10.matrix > test-A10.output

diff -w test-A10.reqd test-A10.output > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A10.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A10.output 
