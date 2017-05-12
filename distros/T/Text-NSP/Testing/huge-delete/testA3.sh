#!/bin/csh

echo "Test A1 for huge-delete.pl"

echo "Running count.pl --newline test-1.output test-1.txt" 
count.pl --newline test-1.output test-1.txt

echo "Running huge-delete.pl --frequency 2 --ufrequency 2 test-1.output test-1.delete1" 
huge-delete.pl --frequency 2 --ufrequency 2 test-1.output test-1.delete1

echo "Running count.pl --newline --frequency 2  --ufrequency 2 test-1.delete2 test-1.txt" 
count.pl --newline --frequency 2 --ufrequency 2 test-1.delete2 test-1.txt

if((-e test-1.delete1) && (-e test-1.delete2)) then
	sort test-1.delete1 > t0
	sort test-1.delete2 > t1
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

/bin/rm -f t0 t1 var test-1.output test-1.delete1 test-1.delete2
