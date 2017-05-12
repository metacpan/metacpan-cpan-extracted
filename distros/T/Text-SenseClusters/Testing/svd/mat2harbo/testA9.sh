#!/bin/csh

echo "Test A9 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 20i4 --param test-A91.mat"

mat2harbo.pl --numform 20i4 --param test-A91.mat > test-A91.output

diff test-A91.output test-A91.reqd > var

diff lap2 test-A91.lap2.reqd > var1

if(-z var && -z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A91.reqd";
	cat var;
	echo "When tested against test-A91.lap2.reqd";
        cat var1;
endif

/bin/rm -f var var1 lap2 test-A91.output
 
echo "Running mat2harbo.pl --param test-A92.mat"

mat2harbo.pl --param test-A92.mat > test-A92.output

diff lap2 test-A92.lap2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A92.lap2.reqd";
        cat var;
endif

/bin/rm -f var lap2 test-A92.output

echo "Running mat2harbo.pl --param test-A93.mat"

mat2harbo.pl --param test-A93.mat >& test-A93.output

diff lap2 test-A93.lap2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A93.lap2.reqd";
        cat var;
endif

/bin/rm -f var lap2 test-A93.output

echo "Running mat2harbo.pl --param test-A94.mat"

mat2harbo.pl --param test-A94.mat >& test-A94.output

diff lap2 test-A94.lap2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A94.lap2.reqd";
        cat var;
endif

/bin/rm -f var lap2 test-A94.output

echo "Running mat2harbo.pl --param test-A95.mat"

mat2harbo.pl --param test-A95.mat >& test-A95.output

diff lap2 test-A95.lap2.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A95.lap2.reqd";
        cat var;
endif

/bin/rm -f var lap2 test-A95.output
