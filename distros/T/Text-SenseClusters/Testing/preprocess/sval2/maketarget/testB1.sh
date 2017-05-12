#!/bin/csh

echo "Test B1 for maketarget.pl"
echo "Running maketarget.pl test-B1.sval2"

maketarget.pl test-B1.sval2 

if(-e "target.regex") then
	echo "Test Error";
        echo "target.regex shouldn't exist."
        /bin/rm -f target.regex
else
	echo "Test Ok";
endif

echo "Test B1a for maketarget.pl"
echo "Running maketarget.pl --head test-B1.sval2"

maketarget.pl --head test-B1.sval2 

if(-e "target.regex") then
	echo "Test Error";
        echo "target.regex shouldn't exist."
        /bin/rm -f target.regex
else
	echo "Test Ok";
endif


