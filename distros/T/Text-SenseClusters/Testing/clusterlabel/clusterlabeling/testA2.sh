#!/bin/csh

echo "Test A2 - Testing clusterlabeling.pl"
echo "Running clusterlabeling.pl --token token.regex --stop stoplist.new --rank 5 --stat ll --prefix testA2 testA2.clusters_context > testA2.output";

clusterlabeling.pl --token token.regex --stop stoplist.new --rank 5 --stat ll --prefix testA2 testA2.clusters_context > testA2.output

diff -w testA2.output testA2.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA2.reqd - ";
	cat var
endif

if(-e testA2.cluster.0) then
 echo "STATUS : OK Cluster file testA2.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA2.cluster.0 NOT created.";
endif

if(-e testA2.cluster.1) then
 echo "STATUS : OK Cluster file testA2.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA2.cluster.1 NOT created.";
endif

/bin/rm -f var testA2.output testA2.cluster.0 testA2.cluster.1 
