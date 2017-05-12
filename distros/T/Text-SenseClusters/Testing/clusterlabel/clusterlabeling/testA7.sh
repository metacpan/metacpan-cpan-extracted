#!/bin/csh

echo "Test A7 - Testing clusterlabeling.pl with stoplist."
echo "Running clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA7 testA7.clusters_context --ngram 3 --stop stoplist.new > testA7.output";

#perl ../../../Toolkit/clusterlabel/clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA7 testA7.clusters_context --ngram 3 --stop stoplist.new > testA7.output
clusterlabeling.pl --token token.regex --window 4 --remove 2 --rank 5 --stat ll --prefix testA7 testA7.clusters_context --ngram 3 --stop stoplist.new > testA7.output

diff -w testA7.output testA7.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA7.reqd - ";
	cat var
endif

if(-e testA7.cluster.0) then
 echo "STATUS : OK Cluster file testA7.cluster.0 created.";
else
 echo "STATUS : ERROR Cluster file testA7.cluster.0 NOT created.";
endif

if(-e testA7.cluster.1) then
 echo "STATUS : OK Cluster file testA7.cluster.1 created.";
else
 echo "STATUS : ERROR Cluster file testA7.cluster.1 NOT created.";
endif

/bin/rm -f var testA7.output testA7.cluster.0 testA7.cluster.1 


