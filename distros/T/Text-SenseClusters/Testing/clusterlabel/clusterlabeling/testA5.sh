#!/bin/csh

echo "Test A5 - Testing clusterlabeling.pl without stoplist."
echo "Running clusterlabeling.pl --token token.regex --rank 5 --stat ll --prefix testA5 testA5.clusters_context > testA5.output";

clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA5 testA5.clusters_context > testA5.output

diff -w testA5.output testA5.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA5.reqd - ";
	cat var
endif

if(-e testA5.cluster.0) then
 echo "STATUS : OK Cluster file testA5.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA5.cluster.0 NOT created.";
endif

if(-e testA5.cluster.1) then
 echo "STATUS : OK Cluster file testA5.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA5.cluster.1 NOT created.";
endif

/bin/rm -f var testA5.output testA5.cluster.0 testA5.cluster.1 
