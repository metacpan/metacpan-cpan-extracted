#!/bin/csh

echo "Test A2 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A2.output test-A2.data"

huge-count.pl --tokenlist --split 20 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A2.output test-A2.data

echo "Running count.pl --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A2.output test-A2.data"

count.pl --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A2.output test-A2.data

# testing split

sort ./test-A2.output/complete-huge-count.output > t0
sort count-A2.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A2.output test-A2.output var

