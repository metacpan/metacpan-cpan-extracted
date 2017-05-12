#!/bin/csh 
echo "TEST A3";
echo "Running report.pl test-A3.map test-A3.matrix ";

report.pl test-A3.map test-A3.matrix > test-A3.output

diff -w test-A3.output test-A3.reqd> variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A3.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A3.output 
