#!/bin/csh

echo "Test B1 for huge-delete.pl"

echo "Running huge-delete.pl --remove 5 --uremove 2 test-1.output test-1.delete1" 
huge-delete.pl --remove 5 --uremove 2 test-1.output test-1.delete1 > t0

echo "Running count.pl --newline --remove 5  --uremove 2 test-1.delete2 test-1.txt" 
count.pl --newline --remove 5 --uremove 2 test-1.delete2 test-1.txt > t1


diff t0 t1 > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f t0 t1 var test-1.output test-1.delete1 test-1.delete2
