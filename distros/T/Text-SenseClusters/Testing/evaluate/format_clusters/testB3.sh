#!/bin/csh

echo "Test B3 - Testing format_clusters.pl without rlabel file."
echo "Running format_clusters.pl testB3.clusol"

format_clusters.pl testB3.clusol >& testB3.output

diff -w testB3.output testB3.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testB3.reqd - ";
	cat var
endif

/bin/rm -f var testB3.output
