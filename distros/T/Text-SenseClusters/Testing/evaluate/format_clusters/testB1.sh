#!/bin/csh

echo "Test B1 - Testing format_clusters.pl with --context and --senseval2 options, both."
echo "Running format_clusters.pl --context testB1.sval2 --senseval2 testB1.sval2 testB1.clusol testB1.rlabel"

format_clusters.pl --context testB1.sval2 --senseval2 testB1.sval2 testB1.clusol testB1.rlabel >& testB1.output

diff -w testB1.output testB1.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testB1.reqd - ";
	cat var
endif

/bin/rm -f var testB1.output
