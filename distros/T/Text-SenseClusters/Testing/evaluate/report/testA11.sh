#!/bin/csh 
echo "TEST A11";
echo "Running report.pl test-A11.map test-A11.matrix ";

report.pl test-A11.map test-A11.matrix > test-A11.output

diff -w test-A11.output test-A11.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A11.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A11.output 
