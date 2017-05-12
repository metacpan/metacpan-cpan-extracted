#!/bin/csh -f

# shell program to test pmi.pm's responses to various erroneous
# conditions. note of course that pmi never halts on errors/warnings
# but sets error codes that statistic.pl can request later on.

# Subtest 1: what happens when ngram > 2 is provided to pmi

echo "Subtest 1"
echo ""

# input file
set TESTFILE = "test-1.sub-1.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# test-1.sub-1.cnt has trigrams in it. so pmi.pm should complain
# during the initialization step, since pmi is for bigrams only!

# required output file
set TARGETFILE = "test-1.sub-1.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 pmi test-1.out $TESTFILE"
statistic.pl --ngram 3 pmi test-1.out $TESTFILE >& error.out

# compare the error output with the required output
diff test-1.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-1.out


# Subtest 2: what happens when all three frequency values are not
# available to pmi

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

# test-1.sub-2.cnt has bigrams in it, but only 2 of the three required frequency values.

# required output file
set TARGETFILE = "test-1.sub-2.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --set_freq_combo $FREQCOMBFILE pmi test-1.out $TESTFILE"
statistic.pl --set_freq_combo $FREQCOMBFILE pmi test-1.out $TESTFILE >& error.out

# compare the error output with the required output
diff error.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-1.out


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
echo "Test:   statistic.pl pmi test-1.out $TESTFILE"
statistic.pl pmi test-1.out $TESTFILE >& error.out

# compare the error output with the required output
diff error.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-1.out


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

# test-1.sub-4.cnt has only one bigram that has "correct"
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
echo "Test:   statistic.pl pmi test-1.out $TESTFILE"
statistic.pl pmi test-1.out $TESTFILE >& error.out

# compare the error output with the required output
diff error.out $TARGETERRORFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output error message matches target error message (as provided in $TARGETERRORFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between error.out and $TARGETERRORFILE :"
    cat difference
endif

# compare the actual output with the required output
diff test-1.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-1.out
