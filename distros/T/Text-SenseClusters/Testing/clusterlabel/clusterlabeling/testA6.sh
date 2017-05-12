#!/bin/csh

echo "Test A6 - Testing clusterlabeling.pl without stoplist."
echo "Running clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA6 testA6.clusters_context --ngram 3> testA6.output";

#perl ../../../Toolkit/clusterlabel/clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA6 testA6.clusters_context --ngram 3> testA6.output
clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA6 testA6.clusters_context --ngram 3> testA6.output

diff -w testA6.output testA6.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA6.reqd - ";
	cat var
endif

if(-e testA6.cluster.0) then
 echo "STATUS : OK Cluster file testA6.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA6.cluster.0 NOT created.";
endif

if(-e testA6.cluster.1) then
 echo "STATUS : OK Cluster file testA6.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA6.cluster.1 NOT created.";
endif

/bin/rm -f var testA6.output testA6.cluster.0 testA6.cluster.1 

