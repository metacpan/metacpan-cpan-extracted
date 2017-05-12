#!/bin/csh

echo "Test A8 for mat2harbo.pl"
echo "Running mat2harbo.pl --numform 8f10.3 --title "Title: Document by Term Matrix for CISI \(1460 by 5609\)" --id bellcist test-A8a.mat"

mat2harbo.pl --numform 8f10.3 --title "Title: Document by Term Matrix for CISI (1460 by 5609)" --id bellcist test-A8a.mat > test-A8a.output

diff test-A8a.output test-A8a.reqd > var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A8a.reqd";
	cat var;
endif

/bin/rm -f var test-A8a.output 
 
echo "Running mat2harbo.pl --numform 8f10.3 --title "Title: Document by Term Matrix for CRAN \(1398 by 4612\)" --id bellcrat test-A8b.mat"

mat2harbo.pl --numform 8f10.3 --title "Title: Document by Term Matrix for CRAN (1398 by 4612)" --id bellcrat test-A8b.mat > test-A8b.output

diff test-A8b.output test-A8b.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8b.reqd";
        cat var;
endif

/bin/rm -f var test-A8b.output

echo "Running mat2harbo.pl --numform 8f10.3 --title "Title: Document by Term Matrix for MED \(1033 by 5831\)" --id bellmedT test-A8c.mat"

mat2harbo.pl --numform 8f10.3 --title "Title: Document by Term Matrix for MED (1033 by 5831)" --id bellmedT test-A8c.mat > test-A8c.output

diff test-A8c.output test-A8c.reqd > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A8c.reqd";
        cat var;
endif

/bin/rm -f var test-A8c.output
