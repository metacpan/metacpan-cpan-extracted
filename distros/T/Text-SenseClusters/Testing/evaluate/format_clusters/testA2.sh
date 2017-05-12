#!/bin/csh

echo "Test A2 - Testing format_clusters.pl with --context options."
echo "Running format_clusters.pl --context testA2.sval2 testA2.clusol testA2.rlabel"

format_clusters.pl --context testA2.sval2 testA2.clusol testA2.rlabel > testA2.output

diff -w testA2.output testA2.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testA2.reqd - ";
	cat var
endif

/bin/rm -f var testA2.output
