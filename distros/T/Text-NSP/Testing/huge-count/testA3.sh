#!/bin/csh

echo "Test A3 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A3.output test-A3.data1 test-A3.data2 test-A3.data3 test-A3.data4"

huge-count.pl --tokenlist --split 20 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A3.output test-A3.data1 test-A3.data2 test-A3.data3 test-A3.data4

# testing split

sort ./test-A3.output/complete-huge-count.output > t0
sort test-A31.reqd > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 test-A3.output var

