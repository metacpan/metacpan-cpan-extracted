#!/bin/csh 
echo "TEST A4";
echo "Running report.pl test-A4.map test-A4.matrix ";

report.pl test-A4.map test-A4.matrix > test-A4.output

diff -w test-A4.output test-A4.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A4.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A4.output 
