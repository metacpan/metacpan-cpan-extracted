#!/bin/csh

echo "Test A1 for count2huge.pl"

count.pl --newline testA1.count testA1.data        

huge-count.pl --tokenlist --newline --split 20 testA1.hugecount testA1.data

count2huge.pl --split 200 testA1.count A1  

if((-e ./A1/count2huge.output) && (-e ./testA1.hugecount/complete-huge-count.output)) then
	diff ./A1/count2huge.output ./testA1.hugecount/complete-huge-count.output > ./A1/var;
endif

if( -z ./A1/var ) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat ./A1/var;
endif

/bin/rm -r A1 testA1.hugecount
/bin/rm -f testA1.count
