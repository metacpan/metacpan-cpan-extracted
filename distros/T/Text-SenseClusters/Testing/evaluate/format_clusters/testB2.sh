#!/bin/csh

echo "Test B2 - Testing format_clusters.pl without cluster_solution file."
echo "Running format_clusters.pl testB2.rlabel"

format_clusters.pl testB2.rlabel >& testB2.output

diff -w testB2.output testB2.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testB2.reqd - ";
	cat var
endif

/bin/rm -f var testB2.output
