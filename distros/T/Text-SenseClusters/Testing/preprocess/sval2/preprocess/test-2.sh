#!/bin/csh -f

# testing for preprocess.pl 
# test 2: shell program to test following options
#	  --xml --noxml --count --nocount   

# Subtest 1: testing with --xml 

echo "Subtest 1: Testing with --xml"

set TESTFILE     = "test-1.xml"

# target files for subtest 1
set TARGETFILE_1 = "test-2.sub-1.xml.reqd"
set TARGETFILE_2 = "test-1.sub-1.word1.count.reqd" 
set TARGETFILE_3 = "test-1.sub-1.word2.count.reqd" 
set TARGETFILE_4 = "test-1.sub-1.word3.count.reqd" 

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

# test with --xml 
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --xml out.xml"
preprocess.pl $TESTFILE --xml out.xml

# find diffs
diff out.xml $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between out.xml and $TARGETFILE_1 :"
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

# find diffs
diff word2.n.count $TARGETFILE_3 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word2.n.count and $TARGETFILE_3 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.count $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.count and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f out.xml
/bin/rm -f word1.n.count
/bin/rm -f word2.n.count
/bin/rm -f word3.n.count

# Subtest 2: testing with --count

echo "Subtest 2: Testing with --count"

set TESTFILE     = "test-1.xml"

# target files for subtest 2
set TARGETFILE_1 = "test-2.sub-2.count.reqd"
set TARGETFILE_2 = "test-1.sub-1.word1.xml.reqd" 
set TARGETFILE_3 = "test-1.sub-1.word2.xml.reqd" 
set TARGETFILE_4 = "test-1.sub-1.word3.xml.reqd" 

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

# test with --count
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --count out.xml"
preprocess.pl $TESTFILE --count out.count

# find diffs
diff out.count $TARGETFILE_1 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between out.count and $TARGETFILE_1 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word1.n.xml $TARGETFILE_2 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word1.n.xml and $TARGETFILE_2 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word2.n.xml $TARGETFILE_3 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word2.n.xml and $TARGETFILE_3 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.xml $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.xml and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f out.count
/bin/rm -f word1.n.xml
/bin/rm -f word2.n.xml
/bin/rm -f word3.n.xml

# Subtest 3: testing with --xml --nocount 

echo "Subtest 3: Testing with --xml and --nocount"

set TESTFILE     = "test-1.xml"

# target files for subtest 3
set TARGETFILE = "test-2.sub-1.xml.reqd"

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# test with --xml --nocount
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --xml out.xml --nocount"
preprocess.pl $TESTFILE --xml out.xml --nocount

# find diffs
diff out.xml $TARGETFILE > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between out.xml and $TARGETFILE :"
    cat difference
endif
/bin/rm -f difference

# check if count files have been created!
if (-e word1.n.count) then
    echo "ERROR: word1.n.count should not have got created, but has got created!!"
    exit
endif 

if (-e word2.n.count) then
    echo "Error: word2.n.count should not have got created, but has got created!!"
    exit
endif 

if (-e word3.n.count) then
    echo "Error: word3.n.count should not have got created, but has got created!!"
    exit
endif 

echo "   No spurious files created"
/bin/rm -f out.xml

# Subtest 4: testing with --count --noxml 

echo "Subtest 4: Testing with --count and --noxml"

set TESTFILE     = "test-1.xml"

# target files for subtest 4
set TARGETFILE = "test-2.sub-2.count.reqd"

# first check if these files exist. if any one does not, quit
if (!(-e $TESTFILE)) then
    echo "File $TESTFILE does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE)) then
    echo "File $TARGETFILE does not exist... aborting"
    exit
endif

# test with --count --noxml
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --count out.count --noxml"
preprocess.pl $TESTFILE --count out.count --noxml

# find diffs
diff out.count $TARGETFILE > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between out.count and $TARGETFILE :"
    cat difference
endif
/bin/rm -f difference

# check if xml files have been created!
if (-e word1.n.xml) then
    echo "ERROR: word1.n.xml should not have got created, but has got created!!"
    exit
endif 

if (-e word2.n.xml) then
    echo "Error: word2.n.xml should not have got created, but has got created!!"
    exit
endif 

if (-e word3.n.xml) then
    echo "Error: word3.n.xml should not have got created, but has got created!!"
    exit
endif 

echo "   No spurious files created"
/bin/rm -f out.count
