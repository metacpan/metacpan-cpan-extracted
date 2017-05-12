#!/bin/csh

echo "Test B2 for huge-merge.pl"
echo "Running huge-merge.pl --keep test-B2" 

huge-merge.pl  --keep test-B2 

sort ./test-B2/merge.1 > ./test-B2/t0
sort ./test-B2/test-B2.reqd > ./test-B2/t1

if ((-e ./test-B2/t0) && (-e ./test-B2/t1)) then
	diff -w ./test-B2/t0 ./test-B2/t1 > ./test-B2/var;
else
    echo "Test Error";
endif


if(-z ./test-B2/var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B2.reqd";
	cat ./test-B2/var;
endif

/bin/rm -f ./test-B2/t0 ./test-B2/t1 ./test-B2/var ./test-B2/merge.1 
