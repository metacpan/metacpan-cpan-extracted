#!/bin/csh -f

# shell program to test dice.pm's output during normal operation (that
# is, when all inputs are correct and as they should be!

# Subtest 1: what happens when the three frequency combinations (0-1,
# 0, 1) are in various different orders

echo "Subtest 1"
echo ""

# input file
set TESTFILE = "test-2.sub-1-a.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# test-2.sub-1.cnt has all the three frequency values in the default
# order, that is: 0-1, 0, 1

# required output file
set TARGETFILE = "test-2.sub-1-a.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl dice test-2.out $TESTFILE" 
statistic.pl dice test-2.out $TESTFILE 

# compare the output with the required output
diff test-2.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-2.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-2.out

# input file
set TESTFILE = "test-2.sub-1-b.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# freq comb file
set FREQCOMBFILE = "test-2.sub-1-b.freq_combo.txt"

# test-2.sub-1.cnt has the three frequency values in the following
# order: 0, 1, 0-1

# required output file
set TARGETFILE = "test-2.sub-1-b.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --set_freq_combo $FREQCOMBFILE dice test-2.out $TESTFILE" 
statistic.pl --set_freq_combo $FREQCOMBFILE dice test-2.out $TESTFILE

# compare the output with the required output
diff test-2.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-2.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-2.out


