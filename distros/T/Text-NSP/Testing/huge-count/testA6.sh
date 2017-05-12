#!/bin/csh

echo "Test A6 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A61.data"

huge-count.pl --tokenlist --split 20 --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A61.data

echo "Running count.pl --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A61.data"

count.pl --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A6.output test-A61.data

# testing split

sort ./test-A6.output/huge-count.output > t0
sort count-A6.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A6.output test-A6.output var

echo "Test A6 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A62.data"

huge-count.pl --tokenlist --split 20 --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A62.data

echo "Running count.pl --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A62.data"

count.pl --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A6.output test-A62.data

# testing split

sort ./test-A6.output/huge-count.output > t0
sort count-A6.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A6.output test-A6.output var

echo "Test A6 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A63.data1 test-A63.data2 test-A63.data3 test-A63.data4"

huge-count.pl --tokenlist --split 20 --remove 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A6.output test-A63.data1 test-A63.data2 test-A63.data3 test-A63.data4

# testing split

sort ./test-A6.output/huge-count.output > t0
sort test-A63.reqd > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A6.output test-A6.output var

