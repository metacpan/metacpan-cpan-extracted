#!/bin/csh

echo "Test A1 for huge-merge.pl"
echo "Running huge-merge.pl --keep test-A1 " 

huge-merge.pl --keep test-A1

sort ./test-A1/merge.* > ./test-A1/t0
sort ./test-A1/test-A1.reqd > ./test-A1/t1

if ((-e ./test-A1/t0) && (-e ./test-A1/t1)) then 
	diff ./test-A1/t0 ./test-A1/t1 > ./test-A1/var;
else
	echo "Test Error";
endif

if( -z ./test-A1/var ) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat ./test-A1/var;
endif

/bin/rm -f ./test-A1/t0 ./test-A1/t1 ./test-A1/var ./test-A1/merge.*
