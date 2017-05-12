#!/bin/csh

echo "Test A3 for maketarget.pl"
echo "Running maketarget.pl --head test-A3.sval2"

maketarget.pl --head test-A3.sval2 

diff -w target.regex test-A3.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex

# --------------------------------------------------
 
echo "Test A3a for maketarget.pl"
echo "Running maketarget.pl test-A3.sval2"

maketarget.pl test-A3.sval2 

diff -w target.regex test-A3a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A3a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 target.regex
 

