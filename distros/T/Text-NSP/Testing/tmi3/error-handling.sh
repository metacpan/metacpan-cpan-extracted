#!/bin/csh -f

# shell program to test tmi3.pm's responses to various erroneous
# conditions. note of course that tmi3 never halts on errors/warnings
# but sets error codes that statistic.pl can request later on.

# ------------------------------------------------------------------
# Subtest 1: what happens when ngram != 3 is provided to tmi3

echo "Subtest 1"
echo ""

# input file
set TESTFILE = "test-1.sub-1.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# test-1.sub-1.cnt has trigrams in it. so tmi3.pm should complain
# during the initialization step, since tmi3 is for trigrams only!

# required output file
set TARGETFILE = "test-1.sub-1.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl tmi3 test-1.out $TESTFILE" 
statistic.pl tmi3 test-1.out $TESTFILE >& error1.out

# compare the error output with the required output

diff error1.out $TARGETFILE > difference1

if (-z difference1) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error1.out and $TARGETFILE :"
    cat difference1
endif

echo ""

/bin/rm -f difference1
/bin/rm -f error1.out
/bin/rm -f test-1.out

# ------------------------------------------------------------------
# Subtest 2: what happens when all 7 frequency values are not
# available to tmi3

echo "Subtest 2"
echo ""

# input file
set TESTFILE = "test-1.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# freq combo file describing above input file's frequency values
set FREQCOMBFILE = "test-1.sub-2.freq_combo.txt"

# check if this file exists. if not, quit!
if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# test-1.sub-2.cnt has trigrams in it, but only 6 of the 7 required frequency values. 

# required output file
set TARGETFILE = "test-1.sub-2.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl tmi3 --ngram 3 --set_freq_combo $FREQCOMBFILE test-2.out $TESTFILE" 
statistic.pl tmi3 --ngram 3 --set_freq_combo $FREQCOMBFILE test-2.out $TESTFILE >& error2.out

# compare the error output with the required output
diff error2.out $TARGETFILE > difference2

if (-z difference2) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error2.out and $TARGETFILE :"
    cat difference2
endif

echo ""

/bin/rm -f difference2
/bin/rm -f error2.out
/bin/rm -f test-2.out

# ------------------------------------------------------------------
# Subtest 3: what happens when the totalBigrams is less equal to 0

echo "Subtest 3"
echo ""

# input file
set TESTFILE = "test-1.sub-3.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# test-1.sub-3.cnt has totalBigrams = -17 in it.

# required output file
set TARGETFILE = "test-1.sub-3.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 tmi3 test-3.out $TESTFILE"
statistic.pl --ngram 3 tmi3 test-3.out $TESTFILE >& error3.out

# compare the error output with the required output
diff error3.out $TARGETFILE > difference3

if (-z difference3) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error3.out and $TARGETFILE :"
    cat difference3
endif

echo ""

/bin/rm -f difference3
/bin/rm -f error3.out
/bin/rm -f test-3.out


# ------------------------------------------------------------------
# Subtest 4: what happens when the frequency values are "wrong"

echo "Subtest 4"
echo ""

# input file
set TESTFILE = "test-1.sub-4.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# test-1.sub-4.cnt has only one trigram that has "correct"
# values. every other is wrong!

# required output file
set TARGETFILE = "test-1.sub-4.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# required error output file
set TARGETERRORFILE = "test-1.sub-4.error.reqd"

if (!(-e $TARGETERRORFILE)) then
    echo "File $TARGETERRORFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl tmi3 test-2.out $TESTFILE"
statistic.pl --ngram 3 tmi3 test-2.out $TESTFILE >& error4.out

# compare the error output with the required output
diff error4.out $TARGETERRORFILE > difference4
if (-z difference4) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETERRORFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error4.out and $TARGETERRORFILE :"
    cat difference4
endif

# compare the actual output with the required output
diff test-2.out $TARGETFILE > difference5
if (-z difference5) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference5
endif

echo ""

/bin/rm -f difference4
/bin/rm -f difference5
/bin/rm -f error4.out
/bin/rm -f test-2.out
