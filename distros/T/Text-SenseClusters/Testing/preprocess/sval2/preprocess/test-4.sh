#!/bin/csh -f

# shell program to test preprocess.pl with unusual token files

# Subtest 1: testing with a three-character token

echo "Subtest 1: Testing with three character token"

set TESTFILE       = "test-4.xml"
set TOKENFILE      = "test-4.sub-1.token.txt"

# target files for subtest 1
set TARGETFILE_1 = "test-4.sub-1.xml.reqd"   
set TARGETFILE_2 = "test-4.sub-1.count.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
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

# do the test
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --token $TOKENFILE"
preprocess.pl $TESTFILE --token $TOKENFILE

# find diffs
diff art.n.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.xml and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff art.n.count $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.count and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f art.n.xml
/bin/rm -f art.n.count

# Subtest 2: testing with a three-alpha-character token

echo "Subtest 2: Testing with three-alphanum-character token"

set TESTFILE       = "test-4.xml"
set TOKENFILE      = "test-4.sub-2.token.txt"

# target files for subtest 2
set TARGETFILE_1 = "test-4.sub-2.xml.reqd"   
set TARGETFILE_2 = "test-4.sub-2.count.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
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

# do the test
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --token $TOKENFILE"
preprocess.pl $TESTFILE --token $TOKENFILE

# find diffs
diff art.n.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.xml and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff art.n.count $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.count and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f art.n.xml
/bin/rm -f art.n.count

# Subtest 3: testing with a word-space-word token

echo "Subtest 3: Testing with word-space-word token"

set TESTFILE       = "test-4.xml"
set TOKENFILE      = "test-4.sub-3.token.txt"

# target files for subtest 3
set TARGETFILE_1 = "test-4.sub-3.xml.reqd"   
set TARGETFILE_2 = "test-4.sub-3.count.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
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

# do the test
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --token $TOKENFILE"
preprocess.pl $TESTFILE --token $TOKENFILE

# find diffs
diff art.n.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.xml and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff art.n.count $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.count and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f art.n.xml
/bin/rm -f art.n.count

# Subtest 4: testing with <head> tokens

echo "Subtest 4: Testing with <head> tokens"

set TESTFILE       = "test-4.xml"
set TOKENFILE      = "test-4.sub-4.token.txt"

# target files for subtest 4
set TARGETFILE_1 = "test-4.sub-4.xml.reqd"   
set TARGETFILE_2 = "test-4.sub-4.count.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
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

# do the test
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --token $TOKENFILE"
preprocess.pl $TESTFILE --token $TOKENFILE

# find diffs
diff art.n.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.xml and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff art.n.count $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between art.n.count and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f art.n.xml
/bin/rm -f art.n.count

