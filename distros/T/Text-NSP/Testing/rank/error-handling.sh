#!/bin/csh -f

# shell program to test rank.pl's response to erroneous conditions. 

# Subtest 1: Check what happens when source file cannot be opened.

echo "Subtest 1: When source file cannot be opened."
echo ""

# required error output file
set TARGETFILE = "test-2.sub-1.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   rank.pl boo >& error.out" 
rank.pl boo >& error.out

# compare the actual output with the required output
diff error.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference 
/bin/rm -f error.out

# Subtest 2: When two files haven't been provided. 

echo "Subtest 2: When two files have not been provided."
echo ""

# a test file is required
set TESTFILE = "test-1-1.txt"

if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required error output file
set TARGETFILE = "test-2.sub-2.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   rank.pl $TESTFILE >& error.out" 
rank.pl $TESTFILE >& error.out

# compare the actual output with the required output
diff error.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference 
/bin/rm -f error.out
