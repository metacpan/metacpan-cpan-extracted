#!/bin/csh

echo "Test A4 - Testing clusterlabeling.pl with Pointwise Mutual Information (pmi) as the test of association."
echo "Running clusterlabeling.pl --token token.regex --rank 5 --remove 6 --stop stoplist.new --stat pmi --prefix testA4 testA4.clusters_context > testA4.reqd";

clusterlabeling.pl --token token.regex --rank 5 --remove 6 --stop stoplist.new --stat pmi --prefix testA4 testA4.clusters_context > testA4.output

diff -w testA4.output testA4.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA4.reqd - ";
	cat var
endif

if(-e testA4.cluster.0) then
 echo "STATUS : OK Cluster file testA4.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA4.cluster.0 NOT created.";
endif

if(-e testA4.cluster.1) then
 echo "STATUS : OK Cluster file testA4.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA4.cluster.1 NOT created.";
endif

/bin/rm -f var testA4.output testA4.cluster.0 testA4.cluster.1 
