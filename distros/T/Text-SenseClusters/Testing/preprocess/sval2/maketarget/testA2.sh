#!/bin/csh

echo "Test A2 for maketarget.pl"
echo "Running maketarget.pl --head test-A2.sval2"

maketarget.pl --head test-A2.sval2 

diff -w target.regex test-A2.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex

# -----------------------------------------------------

echo "Test A2a for maketarget.pl"
echo "Running maketarget.pl test-A2.sval2"

maketarget.pl test-A2.sval2 

diff -w target.regex test-A2a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A2a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex
 

