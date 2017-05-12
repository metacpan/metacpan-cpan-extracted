#!/bin/csh 
echo "TEST A1";
echo "Running report.pl test-A1.map test-A1.matrix ";

report.pl test-A1.map test-A1.matrix > test-A1.output

diff -w test-A1.output test-A1.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A1.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A1.output 
