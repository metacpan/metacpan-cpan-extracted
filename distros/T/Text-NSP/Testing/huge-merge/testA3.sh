#!/bin/csh

echo "Test A3 for huge-merge.pl"
echo "Running huge-merge.pl --keep test-A3" 

huge-merge.pl --keep test-A3

sort ./test-A3/merge.1 > ./test-A3/t0
sort ./test-A3/test-A3.reqd > ./test-A3/t1
if ((-e ./test-A3/t0) && (-e ./test-A3/t1)) then
diff ./test-A3/t0 ./test-A3/t1 > ./test-A3/var
else
    echo "Test Error";
endif




if(-z ./test-A3/var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat ./test-A3/var;
endif

/bin/rm -f ./test-A3/t0 ./test-A3/t1 ./test-A3/var ./test-A3/merge.1
