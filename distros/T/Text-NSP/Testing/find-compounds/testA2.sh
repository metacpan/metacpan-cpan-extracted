#!/bin/csh

echo "Test A2 for find-compounds.pl"
echo "Running find-compounds.pl --newline test-A1.input compoundwords.txt > testA2.out"

find-compounds.pl --newline test-A2.input compoundword.txt > test-A2.out 

if (-e ./test-A2.out) then
	sort test-A2.out > t0;
	sort test-A2.reqd > t1;
	diff t0 t1 > var;
else
	echo "test error";
endif

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f t0 t1 var test-A2.out
