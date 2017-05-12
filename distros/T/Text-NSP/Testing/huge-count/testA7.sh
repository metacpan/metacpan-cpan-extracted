#!/bin/csh

echo "Test A7 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A71.data"

huge-count.pl --tokenlist --split 20 --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A71.data

echo "Running count.pl --frequency 2  --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A71.data"

count.pl --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist count-A7.output test-A71.data

# testing split

sort ./test-A7.output/huge-count.output > t0
sort count-A7.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A7.output test-A7.output var

echo "Test A7 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A72.data"

huge-count.pl --tokenlist --split 20 --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A72.data

echo "Running count.pl --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A72.data"

count.pl --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist count-A7.output test-A72.data

# testing split

sort ./test-A7.output/huge-count.output > t0
sort count-A7.output > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A7.output test-A7.output var

echo "Test A7 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --split 20 --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A73.data1 test-A73.data2 test-A73.data3 test-A73.data4"

huge-count.pl --tokenlist --split 20 --frequency 2 --token token.regex --nontoken nontoken.regex --stop stoplist test-A7.output test-A73.data1 test-A73.data2 test-A73.data3 test-A73.data4

# testing split

sort ./test-A7.output/huge-count.output > t0
sort test-A73.reqd > t1

diff t0 t1 > var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against result of count.pl";
        cat var;
endif

/bin/rm -f -r t0 t1 count-A7.output test-A7.output var

