#!/bin/csh

echo "Test A11 for huge-count.pl"
echo "Running huge-count.pl --tokenlist --newLine --token token.regex --nontoken nontoken.regex --stop stoplist --remove 2 --uremove 3 test-A11.output test-A2.data"

huge-count.pl --tokenlist --newLine --token token.regex --nontoken nontoken.regex --stop stoplist --remove 2 --uremove 3 test-A11.output test-A2.data

echo "count.pl  --newLine --token token.regex --nontoken nontoken.regex --stop stoplist --remove 2 --uremove 3 count-A11.output test-A2.data"
count.pl  --newLine --token token.regex --nontoken nontoken.regex --stop stoplist --remove 2 --uremove 3 count-A11.output test-A2.data

# testing final output

sort test-A11.output/huge-count.output > t0
sort count-A11.output > t1 

diff -w t0 t1 > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against output of count.pl "; 
        cat var1;
endif 

/bin/rm -f -r var1 t0 t1 count-A11.output test-A11.output
