#!/bin/csh

echo "Test B1 for huge-count.pl"
echo "Running huge-count.pl --tokenlist test-B1.output test-B1.data1 test-B1.data2 test-B1.data3"

huge-count.pl --tokenlist test-B1.output test-B1.data1 test-B1.data2 test-B1.data3 >& test-B1.err

diff -w test-B1.err test-B1.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f -r var test-B1.output test-B1.err
