#!/bin/csh -f

# shell program to test statistic.pl's responses to various erroneous
# conditions

# Subtest 1: what happens when the ngram in the input file does not
# have the expected number of tokens

echo "Subtest 1"
echo ""

# input file
set TESTFILE = "test-1.sub-1.cnt"
set PERL5LIB = pwd

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# library file
set LIB = "test_1_sub_3_d.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# subtest 1 a

# test-1.sub-1.cnt has trigrams in it. so statistic.pl should be run with
# --ngram 3. if no --ngram provided, then bigram is assumed and there
# should be an error as defined in test-1.sub-1-a.reqd.

# required output file
set TARGETFILE = "test-1.sub-1-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl $LIB test-1.out $TESTFILE"
statistic.pl $LIB test-1.out $TESTFILE >& error.out

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


# subtest 1 b

# similarly, there should an error when --ngram 4 is used, as defined
# in test-1.sub-1-b.reqd.

# required output file
set TARGETFILE = "test-1.sub-1-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 4 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 4 $LIB test-1.out $TESTFILE >& error.out

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


# subtest 1 c

# finally, there should be no complaint when using --ngram 3

# required output file
set TARGETFILE = "test-1.sub-1-c.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 $LIB test-1.out $TESTFILE >& error.out

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



# Subtest 2: what happens when the number of frequency values in the
# input file does not match with expected value (expected by default
# from the --ngram setting or from the --set_freq_combo setting.

echo "Subtest 2"
echo ""

# input file
set TESTFILE = "test-1.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# library file
set LIB = "test_1_sub_3_d.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# subtest 2 a

# test-1.sub-2.cnt has trigrams in it, but with only 4 frequency
# values as opposed to the possible 7. this file was created using
# test-1.sub-2.freq_combo.txt file with the --set_freq_combo
# switch. so statistic.pl should also be run with --set_freq_combo
# test-1.sub-2.freq_combo.txt. Check what happens if we dont provide
# this file!

# required output file
set TARGETFILE = "test-1.sub-2-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 $LIB test-1.out $TESTFILE >& error.out

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


# subtest 2 b

# there shouldnt be any problems if we use --set_freq_combo test-1.sub-2.freq_combo.txt

# required output file
set TARGETFILE = "test-1.sub-2-b.reqd"
set FREQCOMBFILE = "test-1.sub-2.freq_combo.txt"

# first check if these files exist. if any one does not, quit
if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 --set_freq_comb $FREQCOMBFILE $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 --set_freq_comb $FREQCOMBFILE $LIB test-1.out $TESTFILE >& error.out

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



# Subtest 3: what happens when the mandatory functions
# initializeStatistic() and calculateStatistic() are not defined in
# the statistic library file.

echo "Subtest 3"
echo ""

# input file
set TESTFILE = "test-1.sub-1.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# subtest 3 a

# statistical library file test_1_sub_3_a.pm neither defines nor
# exports the symbols &calculateStatistic and &initializeStatistic
# statistic.pl should give an error! note that since our testfile
# test-1.sub-1.cnt has trigrams, we shall run statistic.pl with
# --ngram 3

# library file
set LIB = "test_1_sub_3_a.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-3-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 $LIB test-1.out $TESTFILE >& error.out

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

# subtest 3 b

# statistical library file test_1_sub_3_b.pm defines
# initializeStatistic but not calculateStatistic.

# library file
set LIB = "test_1_sub_3_b.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-3-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 $LIB test-1.out $TESTFILE >& error.out

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

# subtest 3 c

# statistical library file test_1_sub_3_c.pm defines
# calculateStatistic but not initializeStatistic.

# library file
set LIB = "test_1_sub_3_c.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-3-c.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 $LIB test-1.out $TESTFILE >& error.out

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

# subtest 3 d

# statistical library file test_1_sub_3_d.pm defines both
# calculateStatistic and initializeStatistic, so should not get any
# errors on this one!

# library file
set LIB = "test_1_sub_3_d.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-3-d.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 $LIB test-1.out $TESTFILE"
statistic.pl --ngram 3 $LIB test-1.out $TESTFILE >& error.out

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


# Subtest 4: what happens when the commandline is short on files?!

echo "Subtest 4"
echo ""

# library file for all of subtest 4
set LIB = "test_1_sub_3_d.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# subtest 4 a

# run statistic.pl with only a library

# required output file
set TARGETFILE = "test-1.sub-4-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl $LIB"
statistic.pl $LIB >& error.out

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

# subtest 4 b

# run statistic.pl with only a library and an output file

# required output file
set TARGETFILE = "test-1.sub-4-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl $LIB test-1.out"
statistic.pl $LIB test-1.out >& error.out

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


# Subtest 5: what happens when the input frequency combinations dont
# have the ngram frequency and a frequency cut off is requested?!

echo "Subtest 5"
echo ""

# test file
set TESTFILE = "test-1.sub-5.cnt"

if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# freq combo file
set FREQCOMBFILE = "test-1.sub-5.freq_comb.txt"

if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# library file
set LIB = "test_1_sub_3_d.pm"

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# file test-1.sub-5.cnt does not have the main ngram frequency and has
# only the two marginal totals. a frequency cut off is meaningless
# here, and should be warned off and ignored.

# required output file
set TARGETFILE = "test-1.sub-5.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --frequency 2 --set_freq_combo $FREQCOMBFILE $LIB test-1.out $TESTFILE"
statistic.pl --frequency 2 --set_freq_combo $FREQCOMBFILE $LIB test-1.out $TESTFILE >& error.out

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

# Subtest 6: what happens when the tokens include internal marker <||>
# Test added by Amruta during version 0.71

echo "Subtest 6"
echo ""
echo "Test:   statistic.pl ll test-1.out test-1.sub-6.cnt"
statistic.pl ll test-1.out test-1.sub-6.cnt >& error.out

diff error.out test-1.sub-6.reqd > difference
if(-z difference) then
	echo "Status: OK\!\! Output error message matches target error message (as provided in test-1.sub-6.reqd)"
else
	echo "Status: ERROR\!\! Following differences exist between error.out and test-1.sub-6.reqd :"
    cat difference
endif

echo ""

/bin/rm -f difference error.out test-1.out

/bin/mv -f test_1_sub_3_a.pm test_1_sub_3_a.pm_test
/bin/mv -f test_1_sub_3_b.pm test_1_sub_3_b.pm_test
/bin/mv -f test_1_sub_3_c.pm test_1_sub_3_c.pm_test
/bin/mv -f test_1_sub_3_d.pm test_1_sub_3_d.pm_test
/bin/mv -f test_2.pm test_2.pm_test

/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_a.pm Text/NSP/Measures/2D/test_1_sub_3_a.pm_test
/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_b.pm Text/NSP/Measures/2D/test_1_sub_3_b.pm_test
/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_c.pm Text/NSP/Measures/2D/test_1_sub_3_c.pm_test
/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_d.pm Text/NSP/Measures/2D/test_1_sub_3_d.pm_test
/bin/mv -f Text/NSP/Measures/2D/test_2.pm Text/NSP/Measures/2D/test_2.pm_test
/bin/mv -f Text/NSP/Measures/2D/test-1.pm Text/NSP/Measures/2D/test-1.pm_test

/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_a.pm Text/NSP/Measures/3D/test_1_sub_3_a.pm_test
/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_b.pm Text/NSP/Measures/3D/test_1_sub_3_b.pm_test
/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_c.pm Text/NSP/Measures/3D/test_1_sub_3_c.pm_test
/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_d.pm Text/NSP/Measures/3D/test_1_sub_3_d.pm_test
/bin/mv -f Text/NSP/Measures/3D/test_2.pm Text/NSP/Measures/3D/test_2.pm_test

