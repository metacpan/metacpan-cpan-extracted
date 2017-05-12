#!/bin/csh

echo "Test A3 - Testing clusterlabeling.pl"
echo "Running clusterlabeling.pl --token token.regex --stop stoplist.new --rank 5 --stat ll --prefix testA3 testA3.clusters_context > testA3.output";

clusterlabeling.pl --token token.regex --stop stoplist.new --rank 5 --stat ll --prefix testA3 testA3.clusters_context > testA3.output

diff -w testA3.output testA3.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA3.reqd - ";
	cat var
endif

if(-e testA3.cluster.0) then
 echo "STATUS : OK Cluster file testA3.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA3.cluster.0 NOT created.";
endif

if(-e testA3.cluster.1) then
 echo "STATUS : OK Cluster file testA3.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA3.cluster.1 NOT created.";
endif

/bin/rm -f var testA3.output testA3.cluster.0 testA3.cluster.1 
