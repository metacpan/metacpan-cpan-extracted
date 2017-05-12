#!/bin/csh 
echo "TEST A17";
echo "Running report.pl test-A17.map test-A17.matrix";

report.pl test-A17.map test-A17.matrix > test-A17.output

diff -w test-A17.output test-A17.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A17.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A17.output 
