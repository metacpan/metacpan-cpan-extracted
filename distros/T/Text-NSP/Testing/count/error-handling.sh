#!/bin/csh -f

# shell program to test count.pl's response to erroneous conditions. 

# Subtest 1: check what happens when count.pl is not provided with a source file. 

echo "Subtest 1: When no source file is provided to count.pl"
echo ""

# required error output file
set TARGETFILE = "test-2.sub-1.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl temp >& error.out" 
count.pl temp >& error.out

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
/bin/rm -f temp


# Subtest 2: check what happens when count.pl is provided with a
# source file that doesnt exist!

echo "Subtest 2: When source file does not exist"
echo ""

# required error output file
set TARGETFILE = "test-2.sub-2.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl temp hoho >& error.out" 
count.pl temp hoho >& error.out

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
/bin/rm -f temp


# Subtest 3: check what happens when count.pl is provided with --ngram 0

echo "Subtest 3: --ngram 0"
echo ""

# required error output file
set TARGETFILE = "test-2.sub-3.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 0 >& error.out" 
count.pl --ngram 0 >& error.out

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


# Subtest 4: check what happens when count.pl is provided with --ngram 1 --window 2

echo "Subtest 4: --ngram 1 --window 2"
echo ""

# required error output file
set TARGETFILE = "test-2.sub-4.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 1 --window 2 >& error.out" 
count.pl --ngram 1 --window 2 >& error.out

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


# Subtest 5: check what happens when count.pl is provided with --ngram 3 --window 2

echo "Subtest 5: --ngram 3 --window 2"
echo ""

# required error output file
set TARGETFILE = "test-2.sub-4.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 3 --window 2 >& error.out" 
count.pl --ngram 3 --window 2 >& error.out

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


# Subtest 6: check what happens when count.pl is provided with non
# existent file through --stop.

echo "Subtest 6: Non-existent file through switch --stop"
echo ""

# input file
set TESTFILE = "test-2.txt"

if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required error output file
set TARGETFILE = "test-2.sub-6.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --stop hoho temp $TESTFILE >& error.out" 
count.pl --stop hoho temp $TESTFILE >& error.out

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


# Subtest 7: check what happens when count.pl is provided with non
# existent file through switch --token.

echo "Subtest 7: Non-existent file through switch --token"
echo ""

# input file
set TESTFILE = "test-2.txt"

if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required error output file
set TARGETFILE = "test-2.sub-7.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token hoho temp $TESTFILE >& error.out" 
count.pl --token hoho $TESTFILE >& error.out

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
/bin/rm -f temp


# Subtest 8: check what happens when count.pl is provided with a
# frequency combination file that has indices inconsistent with the
# current --ngram setting.

echo "Subtest 8: Inconsistent frequency combination file"
echo ""

# input file
set TESTFILE = "test-2.txt"

if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# frequency combination file
set FREQCOMBFILE = "test-2.sub-8.freq_combo.txt"

if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# required error output file
set TARGETFILE = "test-2.sub-8.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --set_freq_combo $FREQCOMBFILE temp $TESTFILE >& error.out" 
count.pl --set_freq_combo $FREQCOMBFILE temp $TESTFILE >& error.out

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
/bin/rm -f temp

