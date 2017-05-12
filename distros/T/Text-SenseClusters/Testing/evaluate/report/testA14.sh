#!/bin/csh 
echo "TEST A14";
echo "Running report.pl test-A14.map test-A14.matrix ";

report.pl test-A14.map test-A14.matrix > test-A14.output

diff -w test-A14.output test-A14.reqd > variance

if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A14.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f variance test-A14.output 
