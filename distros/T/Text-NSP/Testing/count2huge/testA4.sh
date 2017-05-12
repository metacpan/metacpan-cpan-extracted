#!/bin/csh

echo "Test A4 for count2huge.pl"

count.pl --newline testA1.count testA1.data        

huge-count.pl --tokenlist --newline --split 20 testA1.hugecount testA1.data

count2huge.pl --split 500 testA1.count A4  

if((-e ./A4/count2huge.output) && (-e ./testA1.hugecount/complete-huge-count.output)) then
diff ./A4/count2huge.output ./testA1.hugecount/complete-huge-count.output > ./A4/var
endif


if( -z ./A4/var ) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat ./A4/var;
endif

/bin/rm -r A4 testA1.hugecount
/bin/rm -f testA1.count
