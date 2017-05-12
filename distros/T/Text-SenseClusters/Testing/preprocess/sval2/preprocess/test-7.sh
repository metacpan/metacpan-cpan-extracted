#!/bin/csh -f

# shell program to test preprocess.pl's --token, 
# --removeNotToken, and --nontoken

# Subtest 1: testing with --token test-7.sub-1.nontoken.txt 

echo "Subtest 1: Testing preprocess.pl with a nontoken file"

set TESTFILE       = "test-7.xml"
set NONTOKENFILE   = "test-7.sub-1.nontoken.txt"

# target files for subtest 1
set TARGETFILE_1 = "test-7.sub-1.xml.reqd"   
set TARGETFILE_2 = "test-7.sub-1.count.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $NONTOKENFILE)) then
    echo "File $NONTOKENFILE does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_1)) then
    echo "File $TARGETFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_2)) then
    echo "File $TARGETFILE_2 does not exist... aborting"
    exit
endif

# test with token file
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --nontoken $NONTOKENFILE"
preprocess.pl $TESTFILE --nontoken $NONTOKENFILE

# find diffs
diff word1.n.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n.xml and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n.count $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n.count and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n.xml
/bin/rm -f word1.n.count

# Subtest 2: testing with --token test-7.sub-2.token.txt 
## and --nontoken test-7.sub-1.nontoken.txt

echo "Subtest 2: Testing preprocess.pl with a nontoken and token file"

set TOKENFILE   = "test-7.sub-2.token.txt"

# target files for subtest 2
set TARGETFILE_1 = "test-7.sub-2.xml.reqd"   
set TARGETFILE_2 = "test-7.sub-2.count.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $NONTOKENFILE)) then
    echo "File $NONTOKENFILE does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_1)) then
    echo "File $TARGETFILE_1 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_2)) then
    echo "File $TARGETFILE_2 does not exist... aborting"
    exit
endif

# test with token and nontoken file

echo "Testing preprocess thusly: preprocess.pl $TESTFILE --token $TOKENFILE --nontoken $NONTOKENFILE"
preprocess.pl $TESTFILE --token $TOKENFILE --nontoken $NONTOKENFILE

# find diffs
diff word1.n.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n.xml and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n.count $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n.count and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n.xml
/bin/rm -f word1.n.count

