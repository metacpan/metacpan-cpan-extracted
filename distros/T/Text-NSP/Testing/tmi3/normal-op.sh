#!/bin/csh -f

# shell program to test tmi3.pm's output during normal operation (that
# is, when all inputs are correct and as they should be!

# Subtest 1: what happens when the 7 frequency combinations are in various 
#different orders

echo "Subtest 1"
echo ""

# input file
set TESTFILE = "test-2.sub-1-a.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# test-2.sub-1.cnt has all the 7 frequency values in the default
# order, 

# required output file
set TARGETFILE = "test-2.sub-1-a.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl tmi3 test-1.out $TESTFILE" 
statistic.pl --ngram 3 tmi3 test-1.out $TESTFILE 

# compare the output with the required output
diff -w test-1.out $TARGETFILE > difference1
if (-z difference1) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-2.out and $TARGETFILE :"
    cat difference1
endif

echo ""

/bin/rm -f difference1
/bin/rm -f test-1.out

# input file
set TESTFILE = "test-2.sub-1-b.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# freq comb file
set FREQCOMBFILE = "test-2.sub-1-b.freq_combo.txt"

# required output file
set TARGETFILE = "test-2.sub-1-b.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --set_freq_combo $FREQCOMBFILE tmi3 test-2.out $TESTFILE" 
statistic.pl --ngram 3 --set_freq_combo $FREQCOMBFILE tmi3 test-2.out $TESTFILE


# compare the output with the required output
diff -w test-2.out $TARGETFILE > difference2
if (-z difference2) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-2.out and $TARGETFILE :"
    cat difference2
endif

echo ""

/bin/rm -f difference2
/bin/rm -f test-2.out

echo "Subtest 3"
echo ""

# this test compares tests ll3 and tmi3 using rank.pl and verifies that the 
# coefficient of correlation is 1

# input file
set TESTFILE = "test-3.sub-1-a.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-3.sub-1-a.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

statistic.pl --ngram 3 --precision 10 tmi3 test-3-tmi3.out $TESTFILE
statistic.pl --ngram 3 --precision 10 ll3 test-3-ll3.out $TESTFILE

rank.pl test-3-tmi3.out test-3-ll3.out > test-3.rank

diff -w test-3.rank $TARGETFILE > difference3
if (-z difference3) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-3.rank and $TARGETFILE :"
    cat difference3
endif

echo ""

/bin/rm difference3
/bin/rm test-3-tmi3.out
/bin/rm test-3-ll3.out
/bin/rm test-3.rank

