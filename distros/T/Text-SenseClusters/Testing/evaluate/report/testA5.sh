#!/bin/csh 
echo "TEST A5";
echo "Running report.pl test-A5.map test-A5.matrix ";

report.pl test-A5.map test-A5.matrix > test-A5.output

diff -w test-A5.output test-A5.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A5.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A5.output 
