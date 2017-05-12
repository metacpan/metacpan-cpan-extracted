#!/bin/csh

echo "Test A3 - Testing format_clusters.pl with --senseval2 options."
echo "Running format_clusters.pl --senseval2 testA3.sval2 testA3.clusol testA3.rlabel"

format_clusters.pl --senseval2 testA3.sval2 testA3.clusol testA3.rlabel > testA3.output

diff -w testA3.output testA3.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testA3.reqd - ";
	cat var
endif

/bin/rm -f var testA3.output
