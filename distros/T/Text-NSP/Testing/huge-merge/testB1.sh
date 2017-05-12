#!/bin/csh

echo "Test B1 for huge-merge.pl"
echo "Running huge-merge.pl --keep test-B1" 

huge-merge.pl -keep test-B1 

sort ./test-B1/merge.1 > ./test-B1/t0
sort ./test-B1/test-B1.reqd > ./test-B1/t1

if ((-e ./test-B1/t0) && (-e ./test-B1/t1)) then
	diff -w ./test-B1/t0 ./test-B1/t1 > ./test-B1/var;
else
    echo "Test Error";
endif




if(-z ./test-B1/var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat ./test-B1/var;
endif

/bin/rm -f ./test-B1/t0 ./test-B1/t1 ./test-B1/var ./test-B1/merge.1 
