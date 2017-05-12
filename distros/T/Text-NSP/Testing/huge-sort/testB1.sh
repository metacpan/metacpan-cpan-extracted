#!/bin/csh

echo "Test B1 for huge-sort.pl"
echo "Running huge-sort.pl --keep test-B1.bigrams" 

huge-sort.pl --keep test-B1.bigrams 

sort test-B1.bigrams-sorted > t0
sort test-B1.reqd > t1

if (-e test-B1.bigrams-sorted) then
diff -w t0 t1 > var
else
    echo "Test Error";
endif

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-B1.reqd";
	cat var;
endif

/bin/rm -f t0 t1 var test-B1.bigrams-sorted
