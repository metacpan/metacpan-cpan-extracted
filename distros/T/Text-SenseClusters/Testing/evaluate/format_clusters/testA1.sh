#!/bin/csh

echo "Test A1 - Testing format_clusters.pl without any options, i.e. the default output format."
echo "Running format_clusters.pl testA1.clusol testA1.rlabel";

format_clusters.pl testA1.clusol testA1.rlabel > testA1.output

diff -w testA1.output testA1.reqd > var

if(-z var) then
        echo "STATUS :  OK Test Results Match.";
else
        echo "STATUS :  ERROR Test Results don't Match....";
        echo "When Tested Against testA1.reqd - ";
	cat var
endif

/bin/rm -f var testA1.output
