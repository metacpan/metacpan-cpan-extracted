#!/bin/csh

echo "Test A9 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --newLine --token token.regex --nontoken nontoken.regex --stop stoplist --split 100 test-A9.output test-A2.data"

huge-count.pl --tokenlist --newLine --token token.regex --nontoken nontoken.regex --stop stoplist --split 100 test-A9.output test-A2.data

# testing final output

sort test-A9.output/complete-huge-count.output > t0
sort test-A9.reqd > t1

diff -w t0 t1 > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A9.reqd/huge-count.output";
        cat var1;
endif 

/bin/rm -f -r var1 t0 t1 test-A9.output
