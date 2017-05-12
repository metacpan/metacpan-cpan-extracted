#!/bin/csh

echo "Test A7 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 8f10.3 --title "Bellcore ADI Linguistics Data" --id belladit test-A7.mat"

mat2harbo.pl --numform 8f10.3 --title "Bellcore ADI Linguistics Data" --id belladit test-A7.mat > test-A7.output

diff test-A7.output test-A7.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A7.reqd";
	cat var;
endif

/bin/rm -f var test-A7.output 
 
