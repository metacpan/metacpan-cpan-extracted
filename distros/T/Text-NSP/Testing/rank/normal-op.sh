#!/bin/csh -f

# shell program to test rank.pl's behaviour under normal working
# conditions.

# Subtest 1: check with files test-1-1.txt and test-1-2.txt -- should
# get -1 and 1 as coefficients for all combinations of these two
# files!

echo "Subtest 1: Do we get -1 and 1?"
echo ""

# input file 
set TESTFILE_1="test-1-1.txt"
set TESTFILE_2="test-1-2.txt"

# check if these files exist. if not, quit!
if (!(-e $TESTFILE_1)) then
    echo "File $TESTFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TESTFILE_2)) then
    echo "File $TESTFILE_2 does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE_1="test-1.sub-1-a.reqd"
set TARGETFILE_2="test-1.sub-1-b.reqd"
set TARGETFILE_3="test-1.sub-1-c.reqd"

if (!(-e $TARGETFILE_1)) then
    echo "File $TARGETFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_2)) then
    echo "File $TARGETFILE_2 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

# now the tests!
echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2" 
rank.pl $TESTFILE_1 $TESTFILE_2 > out

# compare the actual output with the required output
diff out $TARGETFILE_1 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_1)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_1 :"
    cat difference
endif

echo ""

echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_1" 
rank.pl $TESTFILE_1 $TESTFILE_1 > out

# compare the actual output with the required output
diff out $TARGETFILE_2 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_2)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_2 :"
    cat difference
endif

echo ""

echo "Test:   rank.pl $TESTFILE_2 $TESTFILE_2" 
rank.pl $TESTFILE_2 $TESTFILE_2 > out

# compare the actual output with the required output
diff out $TARGETFILE_2 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_3)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_3 :"
    cat difference
endif

echo ""

/bin/rm -f out difference 


# Subtest 2: check when ngrams are tied in one file. 

echo "Subtest 2: Tied ngrams test."
echo ""

# input file 
set TESTFILE_1="test-2-1.txt"
set TESTFILE_2="test-2-2.txt"

# check if these files exist. if not, quit!
if (!(-e $TESTFILE_1)) then
    echo "File $TESTFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TESTFILE_2)) then
    echo "File $TESTFILE_2 does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE="test-1.sub-2.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2" 
rank.pl $TESTFILE_1 $TESTFILE_2 > out

# compare the actual output with the required output
diff out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

# Subtest 3: check when one file has extra ngrams.

echo "Subtest 3: Superfluous ngrams test."
echo ""

# input file 
set TESTFILE_1="test-3-1.txt"
set TESTFILE_2="test-3-2.txt"

# check if these files exist. if not, quit!
if (!(-e $TESTFILE_1)) then
    echo "File $TESTFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TESTFILE_2)) then
    echo "File $TESTFILE_2 does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE="test-1.sub-3.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2" 
rank.pl $TESTFILE_1 $TESTFILE_2 > out

# compare the actual output with the required output
diff out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

# Subtest 4: check --precision

echo "Subtest 4: Checking precision"
echo ""

# input file 
set TESTFILE_1="test-4-1.txt"
set TESTFILE_2="test-4-2.txt"

# check if these files exist. if not, quit!
if (!(-e $TESTFILE_1)) then
    echo "File $TESTFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TESTFILE_2)) then
    echo "File $TESTFILE_2 does not exist... aborting"
    exit
endif

# required output files
set TARGETFILE_1="test-1.sub-4a.reqd"
if (!(-e $TARGETFILE_1)) then
    echo "File $TARGETFILE_1 does not exist... aborting"
    exit
endif

set TARGETFILE_2="test-1.sub-4b.reqd"
if (!(-e $TARGETFILE_2)) then
    echo "File $TARGETFILE_2 does not exist... aborting"
    exit
endif

set TARGETFILE_3="test-1.sub-4c.reqd"
if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

set TARGETFILE_4="test-1.sub-4d.reqd"
if (!(-e $TARGETFILE_4)) then
    echo "File $TARGETFILE_4 does not exist... aborting"
    exit
endif

# now the tests!
echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2" 
rank.pl $TESTFILE_1 $TESTFILE_2 > out

# compare the actual output with the required output
diff out $TARGETFILE_1 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_1)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_1 :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2 --precision 10"
rank.pl $TESTFILE_1 $TESTFILE_2 --precision 10 > out

# compare the actual output with the required output
diff out $TARGETFILE_2 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_2)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_2 :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2 --precision 0"
rank.pl $TESTFILE_1 $TESTFILE_2 --precision 0 > out

# compare the actual output with the required output
diff out $TARGETFILE_3 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_2)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_2 :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2 --precision 1"
rank.pl $TESTFILE_1 $TESTFILE_2 --precision 1 > out

# compare the actual output with the required output
diff out $TARGETFILE_4 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE_4)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE_4 :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

# Subtest 5: check if by reversing the input files we still get the same output. 

echo "Subtest 5: Reversing shouldn't make a difference."
echo ""

# input file 
set TESTFILE_1="test-5-1.txt"
set TESTFILE_2="test-5-2.txt"

# check if these files exist. if not, quit!
if (!(-e $TESTFILE_1)) then
    echo "File $TESTFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TESTFILE_2)) then
    echo "File $TESTFILE_2 does not exist... aborting"
    exit
endif

# required output files
set TARGETFILE="test-1.sub-5.reqd"
if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

echo "Test:   rank.pl $TESTFILE_1 $TESTFILE_2"
rank.pl $TESTFILE_1 $TESTFILE_2 > out

# compare the actual output with the required output
diff out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f out difference 

echo "Test:   rank.pl $TESTFILE_2 $TESTFILE_1"
rank.pl $TESTFILE_2 $TESTFILE_1 > out

# compare the actual output with the required output
diff out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f out difference 
