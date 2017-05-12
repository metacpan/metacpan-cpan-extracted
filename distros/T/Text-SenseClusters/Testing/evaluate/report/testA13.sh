#!/bin/csh 
echo "TEST A13";
echo "Running report.pl test-A13.map test-A13.matrix ";

report.pl test-A13.map test-A13.matrix > test-A13.output

diff -w test-A13.output test-A13.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A13.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A13.output 
