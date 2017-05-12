#!/bin/csh

echo "Test A1 - Testing clusterlabeling.pl for a no label cluster."
echo "Running clusterlabeling.pl testA1.clusters_context --prefix testA1 --rank 5 --window 4 --stop stoplist.new --token token.regex --stat ll --remove 2 > testA1.output";

clusterlabeling.pl testA1.clusters_context --prefix testA1 --rank 5 --window 4 --stop stoplist.new --token token.regex --stat ll --remove 2 > testA1.output

diff -w testA1.output testA1.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA1.reqd - ";
	cat var
endif

if(-e testA1.cluster.-1) then
 echo "STATUS : OK Cluster file testA1.cluster.-1 created.";
else
 echo "STATUS : ERROR Cluster file testA1.cluster.-1 NOT created.";
endif

if(-e testA1.cluster.0) then
 echo "STATUS : OK Cluster file testA1.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA1.cluster.0 NOT created.";
endif

if(-e testA1.cluster.1) then
 echo "STATUS : OK Cluster file testA1.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA1.cluster.1 NOT created.";
endif

/bin/rm -f var testA1.output testA1.cluster.0 testA1.cluster.1 testA1.cluster.-1
