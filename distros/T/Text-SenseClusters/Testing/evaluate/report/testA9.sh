#!/bin/csh 
echo "TEST A9";
echo "Running report.pl test-A9.map test-A9.matrix ";

report.pl test-A9.map test-A9.matrix > test-A9.output

diff -w test-A9.output test-A9.reqd> variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A9.reqd - ";
        cat variance
endif
/bin/rm -f variance test-A9.output 
