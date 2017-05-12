#!/bin/csh -f

# testing for preprocess.pl 
# test 3: shell program to test following options
#	  --split --seed

# Subtest 1: testing with --split 25 --seed 1

echo "Subtest 1: Testing with --split 25 --seed 1"

set TESTFILE     = "test-1.sub-2.word1.xml.reqd"

# target files for subtest 1
set TARGETFILE_1 = "test-3.sub-1.test.count.reqd"
set TARGETFILE_2 = "test-3.sub-1.test.xml.reqd"
set TARGETFILE_3 = "test-3.sub-1.train.count.reqd" 
set TARGETFILE_4 = "test-3.sub-1.train.xml.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
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

if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_4)) then
    echo "File $TARGETFILE_4 does not exist... aborting"
    exit
endif

# do the test
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --split 25 --seed 1"
preprocess.pl $TESTFILE --split 25 --seed 1

# find diffs
diff word1.n-test.count $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-test.count and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n-test.xml $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-test.xml and $TARGETFILE_2 :"
    cat difference
endif

/bin/rm -f difference
# find diffs
diff word1.n-training.count $TARGETFILE_3 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-train.count and $TARGETFILE_3 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n-training.xml $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-train.xml and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n-test.count
/bin/rm -f word1.n-test.xml
/bin/rm -f word1.n-training.count
/bin/rm -f word1.n-training.xml

# Subtest 2: testing with --split 75 --seed 1

echo "Subtest 2: Testing with --split 75 --seed 1"

# target files for subtest 2
set TARGETFILE_1 = "test-3.sub-2.test.count.reqd"
set TARGETFILE_2 = "test-3.sub-2.test.xml.reqd"
set TARGETFILE_3 = "test-3.sub-2.train.count.reqd" 
set TARGETFILE_4 = "test-3.sub-2.train.xml.reqd" 

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
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

if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_4)) then
    echo "File $TARGETFILE_4 does not exist... aborting"
    exit
endif

# do the test
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --split 75 --seed 1"
preprocess.pl $TESTFILE --split 75 --seed 1

# find diffs
diff word1.n-test.count $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-test.count and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n-test.xml $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-test.xml and $TARGETFILE_2 :"
    cat difference
endif

/bin/rm -f difference
# find diffs
diff word1.n-training.count $TARGETFILE_3 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-train.count and $TARGETFILE_3 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n-training.xml $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n-train.xml and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n-test.count
/bin/rm -f word1.n-test.xml
/bin/rm -f word1.n-training.count
/bin/rm -f word1.n-training.xml

