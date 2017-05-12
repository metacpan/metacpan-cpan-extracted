#!/bin/csh

echo "Test A1 for huge-sort.pl"
echo "Running huge-sort.pl --keep test-A1.bigrams"

huge-sort.pl --keep test-A1.bigrams

sort test-A1.bigrams-sorted > t0
sort test-A1.reqd > t1

if (-e test-A1.bigrams-sorted) then
diff t0 t1 > var
else
	echo "Test Error";
endif

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f t0 t1 var test-A1.bigrams-sorted
