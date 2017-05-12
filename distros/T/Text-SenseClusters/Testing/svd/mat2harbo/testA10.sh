#!/bin/csh

echo "Test A10 for mat2harbo.pl"
echo "Running mat2harbo.pl --param --k 4 --numform 8f10.6 test-A10.mat"
mat2harbo.pl --param --k 4 --numform 8f10.6 test-A10.mat > test-A101.output

diff test-A101.output test-A10.reqd > var

diff lap2 test-A101.lap2.reqd > var1

if(-z var && -z var1) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A10.reqd";
	cat var;
	echo "When tested against test-A101.lap2.reqd";
        cat var1;
endif

/bin/rm -f var lap2 var1 test-A101.output 
 

echo "Running mat2harbo.pl --param --rf 2 --k 3 --numform 8f10.6 test-A10.mat"
mat2harbo.pl --param --rf 2 --k 3 --numform 8f10.6 test-A10.mat > test-A102.output

diff test-A102.output test-A10.reqd > var

diff lap2 test-A102.lap2.reqd > var1

if(-z var && -z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10.reqd";
        cat var;
        echo "When tested against test-A102.lap2.reqd";
        cat var1;
endif

/bin/rm -f var lap2 var1 test-A102.output

echo "Running mat2harbo.pl --param --rf 3 --k 7 --numform 8f10.6 test-A10.mat"
mat2harbo.pl --param --rf 3 --k 7 --numform 8f10.6 test-A10.mat > test-A103.output

diff test-A103.output test-A10.reqd > var

diff lap2 test-A103.lap2.reqd > var1

if(-z var && -z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A10.reqd";
        cat var;
        echo "When tested against test-A103.lap2.reqd";
        cat var1;
endif

/bin/rm -f var lap2 var1 test-A103.output

echo "Running mat2harbo.pl --param --iter 3 --rf 1 --k 4 --numform 8f10.6 test-A10.mat"
mat2harbo.pl --param --iter 3 --rf 1 --k 4 --numform 8f10.6 test-A10.mat > test-A104.output

diff lap2 test-A104.lap2.reqd > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A104.lap2.reqd";
        cat var1;
endif

/bin/rm -f lap2 var1 test-A104.output

echo "Running mat2harbo.pl --param test-A10.mat --rf 2 --numform 8f10.6"
mat2harbo.pl --param test-A10.mat --rf 2 --numform 8f10.6 > test-A105.output

diff lap2 test-A105.lap2.reqd > var1
diff test-A105.output test-A10.reqd > var2

if(-z var1 && -z var2) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A105.lap2.reqd";
        cat var1;
	echo "When tested against test-A10.reqd";
        cat var2;
endif

/bin/rm -f lap2 var1 var2 test-A105.output

