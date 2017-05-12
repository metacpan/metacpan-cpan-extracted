#!/bin/csh 
echo "TEST A7";
echo "Running report.pl test-A7.map test-A7.matrix ";

report.pl test-A7.map test-A7.matrix > test-A7.output

diff -w test-A7.output test-A7.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A7.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A7.output 
