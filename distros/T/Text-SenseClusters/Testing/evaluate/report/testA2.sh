#!/bin/csh 
echo "TEST A2";
echo "Running report.pl test-A2.map test-A2.matrix ";

report.pl test-A2.map test-A2.matrix > test-A2.output

diff -w test-A2.output test-A2.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A2.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A2.output 
