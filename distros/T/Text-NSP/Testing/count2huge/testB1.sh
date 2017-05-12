#!/bin/csh

echo "Test B1 for count2huge.pl"

count.pl --newline testA1.count testA1.data

mkdir B1
count2huge.pl --split 10 testA1.count B1 > B1.output 

diff testB1.reqd B1.output  > var

if( -z ./var ) then
	echo "Test Ok";
else
	echo "Test Error";
	cat ./var;
endif

/bin/rm -r B1 B1.output var testA1.count
