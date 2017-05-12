#!/bin/csh

echo "Test A1 for huge-split.pl"

echo "count.pl --newline --tokenlist test-1.output test-1.txt"
count.pl --newline --tokenlist test-1.output test-1.txt

echo "split -l 100 test-1.output"
split -l 100 test-1.output 

echo "huge-split.pl --split 100 test-1.output" 
huge-split.pl --split 100 test-1.output 

diff  test-1.output.1  xaa > var1
diff  test-1.output.2  xab > var2 
diff  test-1.output.3  xac > var3
diff  test-1.output.4  xad > var4 
diff  test-1.output.5  xae > var5 


foreach var (var1 var2 var3 var4 var5)
if(-z $var ) then
	echo "Test Ok";
else
	echo "Test Error";
	cat $var;
endif

/bin/rm -f var* xa* test-1.output*
