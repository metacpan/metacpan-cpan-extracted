#!/bin/csh

echo "Test A2 for count2huge.pl"

count.pl --newline testA1.count testA1.data        

huge-count.pl --tokenlist --newline --split 100 testA1.hugecount testA1.data

count2huge.pl --split 1 testA1.count A2  

if((-e ./A2/count2huge.output) && (-e ./testA1.hugecount/complete-huge-count.output)) then
diff ./A2/count2huge.output ./testA1.hugecount/complete-huge-count.output > ./A2/var
endif

if( -z ./A2/var ) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat ./A2/var;
endif

/bin/rm -r A2 testA1.hugecount
/bin/rm -f testA1.count
