#!/bin/csh 
echo "TEST A15";
echo "Running report.pl test-A15.map test-A15.matrix ";

report.pl test-A15.map test-A15.matrix > test-A15.output

diff -w test-A15.output test-A15.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A15.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A15.output 
