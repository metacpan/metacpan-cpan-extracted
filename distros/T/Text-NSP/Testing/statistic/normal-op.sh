#!/bin/csh -f

# shell program to test statistic.pl's behaviour under normal working
# conditions.

# ---------------------------------------
# Script was originally written by Bano
# ----------------------------------------------------------------------------
# 				changelog
#
# version	Date		Updater	 Changes done		   ChangeId

# 0.53		01/09/2003	Amruta	 fixed the problem of 	    ADP.53.1
#					 missing sort operations
#					 before test result
#					 comparisions
# -----------------------------------------------------------------------------

# library file for whole testing
/bin/mv -f ./test_1_sub_3_a.pm_test ./test_1_sub_3_a.pm
/bin/mv -f ./test_1_sub_3_b.pm_test ./test_1_sub_3_b.pm
/bin/mv -f ./test_1_sub_3_c.pm_test ./test_1_sub_3_c.pm
/bin/mv -f ./test_1_sub_3_d.pm_test ./test_1_sub_3_d.pm
/bin/mv -f ./test_2.pm_test ./test_2.pm

/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_a.pm_test Text/NSP/Measures/2D/test_1_sub_3_a.pm
/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_b.pm_test Text/NSP/Measures/2D/test_1_sub_3_b.pm
/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_c.pm_test Text/NSP/Measures/2D/test_1_sub_3_c.pm
/bin/mv -f Text/NSP/Measures/2D/test_1_sub_3_d.pm_test Text/NSP/Measures/2D/test_1_sub_3_d.pm
/bin/mv -f Text/NSP/Measures/2D/test_2.pm_test Text/NSP/Measures/2D/test_2.pm
/bin/mv -f Text/NSP/Measures/2D/test-1.pm_test Text/NSP/Measures/2D/test-1.pm

/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_a.pm_test Text/NSP/Measures/3D/test_1_sub_3_a.pm
/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_b.pm_test Text/NSP/Measures/3D/test_1_sub_3_b.pm
/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_c.pm_test Text/NSP/Measures/3D/test_1_sub_3_c.pm
/bin/mv -f Text/NSP/Measures/3D/test_1_sub_3_d.pm_test Text/NSP/Measures/3D/test_1_sub_3_d.pm
/bin/mv -f Text/NSP/Measures/3D/test_2.pm_test Text/NSP/Measures/3D/test_2.pm

set LIB = "test_2.pm"
set PERL5LIB = `pwd`

if (!(-e $LIB)) then
    echo "File $LIB does not exist... aborting"
    exit
endif

# Subtest 1: check to see if set_freq_combo and get_freq_combo is
# working or not!

echo "Subtest 1"
echo ""

# input file
set TESTFILE = "test-2.sub-1-a.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# freq combo file
set FREQCOMBFILE = "test-2.sub-1-a.freq_combo.txt"

# check if this file exists. if not, quit!
if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# test-2.sub-1-a.cnt has trigrams in it but without all the frequency
# values. set_freq_combo is required. we will use it and then do a
# get_freq_combo to see if we are getting the right combinations!

# required output file
set TARGETFILE = "test-2.sub-1-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --ngram 3 --set_freq_combo $FREQCOMBFILE --get_freq_combo freq.out $LIB test-2.out $TESTFILE"
statistic.pl --ngram 3 --set_freq_combo $FREQCOMBFILE --get_freq_combo freq.out $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-2.out and $TARGETFILE :"
    cat difference
endif

# compare output from get_freq_combo with the file passed through
# set_freq_combo. should be the same.
diff -b freq.out $FREQCOMBFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output frequency combination file matches target frequency combination file (as provided in $FREQCOMBFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between freq.out and $FREQCOMBFILE :"
    cat difference
endif

echo ""

/bin/rm -f difference
/bin/rm -f error.out
/bin/rm -f test-2.out
/bin/rm -f freq.out


# Subtest 2: check to see if --frequency is working or not

echo "Subtest 2"
echo ""

# input file
set TESTFILE = "test-2.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# subtest 2 a

# test-2.sub-2.cnt has bigrams in it; one with freq 3, three with freq
# 2, etc. with --frequency 2, we should have only these four bigrams
# left.

# required output file
set TARGETFILE = "test-2.sub-2-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --frequency 2 $LIB test-2.out $TESTFILE"
statistic.pl --frequency 2 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out

# subtest 2 b

# test-2.sub-2.cnt has bigrams in it; one with freq 3, three with freq
# 2, etc. with --frequency 3, we should have only one bigram left.

# required output file
set TARGETFILE = "test-2.sub-2-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --frequency 3 $LIB test-2.out $TESTFILE"
statistic.pl --frequency 3 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out
/bin/rm -f t1
/bin/rm -f t2

# Subtest 3: check to see if --rank is working or not

echo "Subtest 3"
echo ""

# input file
set TESTFILE = "test-2.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# subtest 3 a

# using test_2.pm, each of the 7 bigrams get different ranks. we
# should get top 6 with --rank 6.

# required output file
set TARGETFILE = "test-2.sub-3-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --rank 6 $LIB test-2.out $TESTFILE"
statistic.pl --rank 6 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out

# subtest 3 b

# what do we get with --rank 3?!

# required output file
set TARGETFILE = "test-2.sub-3-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --rank 3 $LIB test-2.out $TESTFILE"
statistic.pl --rank 3 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out



# Subtest 4: check to see if --precision is working or not

echo "Subtest 4"
echo ""

# input file
set TESTFILE = "test-2.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# subtest 4 a

# try with precision 0. should get no places of decimal.

# required output file
set TARGETFILE = "test-2.sub-4-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --precision 0 $LIB test-2.out $TESTFILE"
statistic.pl --precision 0 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out

# subtest 4 b

# --precision 5?

# required output file
set TARGETFILE = "test-2.sub-4-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --precision 5 $LIB test-2.out $TESTFILE"
statistic.pl --precision 5 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out

# subtest 4 c

# --precision 10?

# required output file
set TARGETFILE = "test-2.sub-4-c.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --precision 10 $LIB test-2.out $TESTFILE"
statistic.pl --precision 10 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out


# Subtest 5: check to see if --score is working is working or not

echo "Subtest 5"
echo ""

# input file
set TESTFILE = "test-2.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# subtest 5 a

# try with score cutoff 0.8

# required output file
set TARGETFILE = "test-2.sub-5-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --score 0.8 $LIB test-2.out $TESTFILE"
statistic.pl --score 0.8 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out

# subtest 5 b

# --score 1.2?

# required output file
set TARGETFILE = "test-2.sub-5-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --score 1.2 $LIB test-2.out $TESTFILE"
statistic.pl --score 1.2 $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out


# Subtest 6: check to see if --format is working or not

echo "Subtest 6"
echo ""

# input file
set TESTFILE = "test-2.sub-2.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-2.sub-6.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --format $LIB test-2.out $TESTFILE"
statistic.pl --format $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out


# Subtest 7: check to see if --extended is working or not

echo "Subtest 7"
echo ""

# input file
set TESTFILE = "test-2.sub-7.cnt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# subtest 7 a

# first check with the --extended switch in place

# required output file
set TARGETFILE = "test-2.sub-7-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl --extended $LIB test-2.out $TESTFILE"
statistic.pl --extended $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out

# subtest 7 b

# next check without the --extended switch in place

# required output file
set TARGETFILE = "test-2.sub-7-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   statistic.pl $LIB test-2.out $TESTFILE"
statistic.pl $LIB test-2.out $TESTFILE

# compare the actual output with the required output
# --------
# ADP.53.1
# --------
sort test-2.out > t1
sort $TARGETFILE > t2
diff -w t1 t2 > difference
#diff test-2.out $TARGETFILE > difference
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
/bin/rm -f freq.out
/bin/rm -f t1
/bin/rm -f t2
