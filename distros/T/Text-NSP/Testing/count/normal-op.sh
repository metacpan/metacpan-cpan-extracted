#!/bin/csh -f

# shell program to test count.pl's behaviour under normal working
# conditions.

# Subtest 1: check --token using an eclectic collection of token
# definitions ;)

echo "Subtest 1: Checking --token"
echo ""

# Subtest 1a: using /\w+/

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input token definition file
set TOKENFILE = "test-1.sub-1-a.token.txt"

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-1-a.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token $TOKENFILE test-1.out $TESTFILE" 
count.pl --token $TOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 1b: using /[.,;:']/

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input token definition file
set TOKENFILE = "test-1.sub-1-b.token.txt"

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-1-b.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token $TOKENFILE test-1.out $TESTFILE" 
count.pl --token $TOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 1c: using following regexs:

#   /th/
#   /nd/
#   /\w+/

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input token definition file
set TOKENFILE = "test-1.sub-1-c.token.txt"

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-1-c.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token $TOKENFILE test-1.out $TESTFILE" 
count.pl --token $TOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 1d: using following regex: /.../

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input token definition file
set TOKENFILE = "test-1.sub-1-d.token.txt"

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-1-d.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token $TOKENFILE test-1.out $TESTFILE" 
count.pl --token $TOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 1e: using following regex: /.../

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input token definition file
set TOKENFILE = "test-1.sub-1-e.token.txt"

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-1-e.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token $TOKENFILE test-1.out $TESTFILE" 
count.pl --token $TOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 1f: using following regex: /.../

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input token definition file
set TOKENFILE = "test-1.sub-1-f.token.txt"

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-1-f.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --token $TOKENFILE test-1.out $TESTFILE" 
count.pl --token $TOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 2: check --ngram and --window 

echo "Subtest 2: Checking --ngram and --window"
echo ""

# Subtest 2a: using --ngram 3

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-2-a.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 3 test-1.out $TESTFILE" 
count.pl --ngram 3 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 2b: using --ngram 3 --window 4

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-2-b.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 3 --window 4 test-1.out $TESTFILE" 
count.pl --ngram 3 --window 4 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 2c: using --ngram 4 

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-2-c.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 4 test-1.out $TESTFILE" 
count.pl --ngram 4 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 2d: using --ngram 4 --window 5 

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-2-d.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 4 --window 5 test-1.out $TESTFILE" 
count.pl --ngram 4 --window 5 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out

# Subtest 2e: using --ngram 1

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-2-e.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 1 test-1.out $TESTFILE" 
count.pl --ngram 1 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out

# Subtest 3: check --get_freq_combo and --set_freq_combo

echo "Subtest 3: Checking --get_freq_combo and --set_freq_combo"
echo ""

# Subtest 3a: using --get_freq_combo and --ngram 3

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-3-a.freq_combo.txt"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --get_freq_comb test-1.out --ngram 3 temp $TESTFILE" 
count.pl --get_freq_comb test-1.out --ngram 3 temp $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out
/bin/rm -f temp

# Subtest 3b: using --get_freq_combo and --ngram 4

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-3-b.freq_combo.txt"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --get_freq_comb test-1.out --ngram 4 temp $TESTFILE" 
count.pl --get_freq_comb test-1.out --ngram 4 temp $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out
/bin/rm -f temp

# Subtest 3c: using --set_freq_combo and --ngram 3

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input freqcomb file
set FREQCOMBFILE = "test-1.sub-3-c.freq_combo.txt"

if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-3-c.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 3 --set_freq_combo $FREQCOMBFILE --get_freq_comb test-1.freq_combo.out test-1.out $TESTFILE" 
count.pl --ngram 3 --set_freq_combo $FREQCOMBFILE --get_freq_comb test-1.freq_combo.out test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

diff -w test-1.freq_combo.out $FREQCOMBFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $FREQCOMBFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $FREQCOMBFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out
/bin/rm -f test-1.freq_combo.out 

# Subtest 3d: using --set_freq_combo and --ngram 4

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# input freqcomb file
set FREQCOMBFILE = "test-1.sub-3-d.freq_combo.txt"

if (!(-e $FREQCOMBFILE)) then
    echo "File $FREQCOMBFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-3-d.reqd"   

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 4 --set_freq_combo $FREQCOMBFILE --get_freq_comb test-1.freq_combo.out test-1.out $TESTFILE" 
count.pl --ngram 4 --set_freq_combo $FREQCOMBFILE --get_freq_comb test-1.freq_combo.out test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

diff -w test-1.freq_combo.out $FREQCOMBFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $FREQCOMBFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $FREQCOMBFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out
/bin/rm -f test-1.freq_combo.out 


# Subtest 4: check --stop

echo "Subtest 4: Checking --stop"
echo ""

# Subtest 4a: using --stop 

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# stop file
set STOPFILE = "test-1.sub-4.stop.txt"

if (!(-e $STOPFILE)) then
    echo "File $STOPFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-4-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --stop $STOPFILE test-1.out $TESTFILE" 
count.pl --stop $STOPFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 4b: using --stop and --ngram 4

# input file 
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# stop file
set STOPFILE = "test-1.sub-4.stop.txt"

if (!(-e $STOPFILE)) then
    echo "File $STOPFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-4-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 4 --stop $STOPFILE test-1.out $TESTFILE" 
count.pl --ngram 4 --stop $STOPFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out

# -------------------------------------------------------------------------
# Subtests 4c, 4d, 4e here are added by Amruta on Jan 07, 2003 to test new 
# features of stop list like Perl regex support, AND, OR modes 
# -------------------------------------------------------------------------
# Subtest 4c: using --stop in default mode when @stop.mode is not specified 

# input file
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# stop file
set STOPFILE = "test-1.sub-4-c.stop.txt"

if (!(-e $STOPFILE)) then
    echo "File $STOPFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-4-c.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --stop $STOPFILE test-1.out $TESTFILE"
count.pl --stop $STOPFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference

if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-1.out

# Subtest 4d: using --stop in OR mode when @stop.mode=OR in stop file
 
# input file
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# stop file
set STOPFILE = "test-1.sub-4-d.stop.txt"

if (!(-e $STOPFILE)) then
    echo "File $STOPFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-4-d.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --stop $STOPFILE test-1.out $TESTFILE"
count.pl --stop $STOPFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-1.out

# Subtest 4e: using --stop in AND mode when @stop.mode=AND in stop file

# input file
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# stop file
set STOPFILE = "test-1.sub-4-e.stop.txt"

if (!(-e $STOPFILE)) then
    echo "File $STOPFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-4-e.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --stop $STOPFILE test-1.out $TESTFILE"
count.pl --stop $STOPFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference

if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-1.out


# Subtest 5: check --frequency and --remove

echo "Subtest 5: Checking --frequency and --remove"
echo ""

# Subtest 5a: using --frequency 2

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-5-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --frequency 2 test-1.out $TESTFILE" 
count.pl --frequency 2 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 5b: using --frequency 4

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-5-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --frequency 4 test-1.out $TESTFILE" 
count.pl --frequency 4 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 5c: using --remove 2

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-5-c.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --remove 2 test-1.out $TESTFILE" 
count.pl --remove 2 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 5d: using --remove 4

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-5-d.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --remove 4 test-1.out $TESTFILE" 
count.pl --remove 4 test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 6: check --newLine

echo "Subtest 6: Checking --newLine"
echo ""

# Subtest 6a: not using --newLine

# input file 
set TESTFILE = "test-1.sub-6.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-6-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl test-1.out $TESTFILE" 
count.pl test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 6b: using --frequency 4

# input file 
set TESTFILE = "test-1.sub-6.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-6-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --newLine test-1.out $TESTFILE" 
count.pl --newLine test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out


# Subtest 7: check --histogram

echo "Subtest 7: Checking --histogram"
echo ""

# Subtest 7a: using --histogram with bigrams

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-7-a.histo.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --histogram test-1.out temp $TESTFILE" 
count.pl --histogram test-1.out temp $TESTFILE

# compare the actual output with the required output
diff test-1.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out
/bin/rm -f temp

# Subtest 7b: using --histogram and --ngram 3

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-7-b.histo.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --ngram 3 --histogram test-1.out temp $TESTFILE" 
count.pl --ngram 3 --histogram test-1.out temp $TESTFILE

# compare the actual output with the required output
diff test-1.out $TARGETFILE > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out
/bin/rm -f temp


# Subtest 8: check --recurse

echo "Subtest 8: Checking --recurse"
echo ""

# Subtest 8a: not using --recurse, and giving a data directory

# input file 
set TESTDIR = "data-dir"

# check if this directory exists. if not, quit!  
if (!(-e $TESTDIR)) then
    echo "File $TESTDIR does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-8-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl test-1.out $TESTDIR" 
count.pl test-1.out $TESTDIR

# compare the actual output with the required output
sort test-1.out > t1 
sort $TARGETFILE > t2
diff -w t1 t2 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out t1 t2

# Subtest 8b: using --recurse

# input file 
set TESTDIR = "data-dir"

# check if this file exists. if not, quit!  
if (!(-e $TESTDIR)) then
    echo "File $TESTDIR does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-8-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --recurse test-1.out $TESTDIR" 
count.pl --recurse test-1.out $TESTDIR

# compare the actual output with the required output
sort test-1.out > t1
sort $TARGETFILE > t2
diff t1 t2 > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out t1 t2


# Subtest 9: check --extended

echo "Subtest 9: Checking --extended"
echo ""

# Subtest 9a: not using --extended, and giving a data directory

# input file 
set TESTFILE = "test-1.sub-5.txt"

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting" 
    exit 
endif

# required output file
set TARGETFILE = "test-1.sub-9.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --extended test-1.out $TESTFILE" 
count.pl --extended test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference 
/bin/rm -f test-1.out

# -------------------------------------------------------------------------
# Subtest 10 is added by Amruta on 01/07/2003 to test the --nontoken option
# ------------------------------------------------------------------------- 
# Subtest 10 : Check --nontoken
echo "Subtest 10: Checking --nontoken"
echo ""

# Subtest 10a: using single nontoken regex /(o|O)(n|N)/ to remove every
# occurrence of on,On,ON,oN from the input stream

# input file
set TESTFILE = "test-1.txt"
set NONOKENFILE = "test-1.sub-10-a.nontoken.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-10-a.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --nontoken $NONOKENFILE test-1.out $TESTFILE"
count.pl --nontoken $NONOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-1.out

# Subtest 10b: using following nontoken regexs 
# /is/
# /th/
# /nd/
# To remove every occurrence of is,th and nd

# input file
set TESTFILE = "test-1.txt"
set NONOKENFILE = "test-1.sub-10-b.nontoken.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-10-b.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --nontoken $NONOKENFILE test-1.out $TESTFILE"
count.pl --nontoken $NONOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-1.out

# Subtest 10c: using following nontoken regexs
# /i./
# /.e/
# /[A-Z]/
# To remove every occurrence of 
# 'i' and its following character 
# 'e' and its preceding character 
# and any uppercase letter

# input file
set TESTFILE = "test-1.txt"
set NONOKENFILE = "test-1.sub-10-c.nontoken.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-10-c.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --nontoken $NONOKENFILE test-1.out $TESTFILE"
count.pl --nontoken $NONOKENFILE test-1.out $TESTFILE

# compare the actual output with the required output
sort test-1.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-1.out

# -------------------------------------------------------------------------
# Subtest 11 is added by Ying on 02/08/2010 to test the --tokenlist option
# ------------------------------------------------------------------------- 
# Subtest 11 : Check --tokenlist

echo "Subtest 11: Checking --tokenlist"
echo ""

# input file
set TESTFILE = "test-1.txt"

# check if this file exists. if not, quit!
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

# required output file
set TARGETFILE = "test-1.sub-11.reqd"

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# now the test!
echo "Test:   count.pl --tokenlist test-11.out $TESTFILE"
count.pl --tokenlist test-11.out $TESTFILE

# compare the actual output with the required output
sort test-11.out > one
sort $TARGETFILE > two
diff one two > difference
if (-z difference) then
    echo "Status: OK\!\! Output matches target output (as provided in $TARGETFILE)"
else
    echo "Status: ERROR\!\! Following differences exist between test-1.out and $TARGETFILE :"
    cat difference
endif

echo ""

/bin/rm -f one two difference
/bin/rm -f test-11.out



