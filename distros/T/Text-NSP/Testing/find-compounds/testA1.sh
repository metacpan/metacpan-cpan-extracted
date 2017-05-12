#!/bin/csh

echo "Test A1 for find-compounds.pl"
echo "Running find-compounds.pl --newline test-A1.input compoundwords.txt > test-A1.out"

find-compounds.pl --newline test-A1.input compoundword.txt > test-A1.out 


if (-e ./test-A1.out) then 
	sort test-A1.out > t0;
	sort test-A1.reqd > t1;
	diff t0 t1 > var;
else
	echo "test error";
endif

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f t0 t1 var test-A1.out
