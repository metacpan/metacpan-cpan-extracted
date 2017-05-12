#!/bin/csh

echo "Test A4 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A41.data"

huge-count.pl --tokenlist --split 20 --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A41.data

echo "Running count.pl --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A41.data"

count.pl --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A4.output test-A41.data

# testing split

sort ./test-A4.output/huge-count.output > t0
sort count-A4.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A4.output test-A4.output var

echo "Test A4 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A42.data"

huge-count.pl --tokenlist --split 20 --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A42.data

echo "Running count.pl --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A42.data"

count.pl --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist count-A4.output test-A42.data

# testing split

sort ./test-A4.output/huge-count.output > t0
sort count-A4.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A4.output test-A4.output var

echo "Test A4 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A43.data1 test-A43.data2 test-A43.data3 test-A43.data4"

huge-count.pl --tokenlist --split 20 --frequency 2 --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A4.output test-A43.data1 test-A43.data2 test-A43.data3 test-A43.data4

# testing split

sort ./test-A4.output/huge-count.output > t0
sort test-A43.reqd > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A4.output test-A4.output var

