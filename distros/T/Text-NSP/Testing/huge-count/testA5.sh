#!/bin/csh

echo "Test A5 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A51.data"

huge-count.pl --tokenlist --split 20 --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A51.data

echo "Running count.pl --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A51.data"

count.pl --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A5.output test-A51.data

# testing split

sort ./test-A5.output/complete-huge-count.output > t0
sort count-A5.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A5.output test-A5.output var

echo "Test A5 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A52.data"

huge-count.pl --tokenlist --split 20 --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A52.data

echo "Running count.pl --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A52.data"

count.pl --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A5.output test-A52.data

# testing split

sort ./test-A5.output/complete-huge-count.output > t0
sort count-A5.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A5.output test-A5.output var

echo "Test A5 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A53.data1 test-A53.data2 test-A53.data3 test-A53.data4"

huge-count.pl --tokenlist --split 20 --window 3 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A5.output test-A53.data1 test-A53.data2 test-A53.data3 test-A53.data4

# testing split

sort ./test-A5.output/complete-huge-count.output > t0
sort test-A53.reqd > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A5.output test-A5.output var

