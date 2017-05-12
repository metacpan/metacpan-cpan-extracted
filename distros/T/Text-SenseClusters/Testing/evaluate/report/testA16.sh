#!/bin/csh 
echo "TEST A16";
echo "Running report.pl test-A16.map test-A16.matrix";

report.pl test-A16.map test-A16.matrix > test-A16.output

diff -w test-A16.output test-A16.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A16.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A16.output 
