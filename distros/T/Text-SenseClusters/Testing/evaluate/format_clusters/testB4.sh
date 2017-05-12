#!/bin/csh

echo "Test B4 - Testing format_clusters.pl without cluster_solution and rlabel file."
echo "Running format_clusters.pl "

format_clusters.pl >& testB4.output

diff -w testB4.output testB4.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testB4.reqd - ";
	cat var
endif

/bin/rm -f var testB4.output
