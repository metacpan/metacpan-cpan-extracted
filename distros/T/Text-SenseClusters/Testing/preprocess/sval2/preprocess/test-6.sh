#!/bin/csh -f

# shell program to test preprocess.pl's --sentence_boundary

# Subtest 1: testing without any options

echo "Subtest 1: Testing without options."

set TESTFILE       = "test-6.xml"
set TOKENFILE      = "test-6.token.txt"
set TARGETFILE_1   = "test-6.xml.reqd"   
set TARGETFILE_2   = "test-6.count.reqd" 

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

if (!(-e $TOKENFILE)) then
    echo "File $TOKENFILE does not exist... aborting"
    exit
endif

# test!
echo "Testing preprocess thusly: preprocess.pl --putSentenceTags --token $TOKENFILE $TESTFILE"
preprocess.pl --putSentenceTags --token $TOKENFILE $TESTFILE

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
