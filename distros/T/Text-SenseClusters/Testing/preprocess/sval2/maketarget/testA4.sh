#!/bin/csh

echo "Test A4 for maketarget.pl"
echo "Running maketarget.pl --head test-A4.sval2"

maketarget.pl --head test-A4.sval2 

diff -w target.regex test-A4.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex

# -------------------------------------------------

echo "Test A4a for maketarget.pl"
echo "Running maketarget.pl test-A4.sval2"

maketarget.pl test-A4.sval2 

diff -w target.regex test-A4a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A4a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex
 
