#!/bin/csh

echo "Test A1 for maketarget.pl"
echo "Running maketarget.pl --head test-A1.sval2"

maketarget.pl --head test-A1.sval2 

diff -w target.regex test-A1.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex

# ---------------------------------------------------

echo "Test A1a for maketarget.pl"
echo "Running maketarget.pl test-A1.sval2"

maketarget.pl test-A1.sval2 

diff -w target.regex test-A1a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex
 

