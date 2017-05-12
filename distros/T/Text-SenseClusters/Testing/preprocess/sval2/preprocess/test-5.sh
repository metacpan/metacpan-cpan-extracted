#!/bin/csh -f

# shell program to test preprocess.pl's --token, --useLexelt, 
# --useSenseid options and --removeNonTokens given an input file without
# any new line characters

# Subtest 1: testing without any options

echo "Subtest 1: Testing without options."

set TESTFILE       = "test-5.xml"

# target files for subtest 1
set TARGETFILE_1 = "test-1.sub-1.word1.xml.reqd"   
set TARGETFILE_2 = "test-1.sub-1.word1.count.reqd" 
set TARGETFILE_3 = "test-1.sub-1.word2.xml.reqd"   
set TARGETFILE_4 = "test-1.sub-1.word2.count.reqd" 
set TARGETFILE_5 = "test-1.sub-1.word3.xml.reqd"   
set TARGETFILE_6 = "test-1.sub-1.word3.count.reqd" 

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

if (!(-e $TARGETFILE_5)) then
    echo "File $TARGETFILE_5 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_6)) then
    echo "File $TARGETFILE_6 does not exist... aborting"
    exit
endif

# test without any commandline options
echo "Testing preprocess thusly: preprocess.pl $TESTFILE"
preprocess.pl $TESTFILE 

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
diff word2.n.count $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word2.n.count and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.xml $TARGETFILE_5 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.xml and $TARGETFILE_5 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.count $TARGETFILE_6 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.count and $TARGETFILE_6 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n.xml
/bin/rm -f word1.n.count
/bin/rm -f word2.n.xml
/bin/rm -f word2.n.count
/bin/rm -f word3.n.xml
/bin/rm -f word3.n.count

# Subtest 2: testing with --token test-1.sub-2.token.txt

echo "Subtest 2: Testing preprocess.pl with a token file"

set TESTFILE       = "test-5.xml"
set TOKENFILE      = "test-1.sub-2.token.txt"

# target files for subtest 2
set TARGETFILE_1 = "test-1.sub-2.word1.xml.reqd"   
set TARGETFILE_2 = "test-1.sub-2.word1.count.reqd" 
set TARGETFILE_3 = "test-1.sub-2.word2.xml.reqd"   
set TARGETFILE_4 = "test-1.sub-2.word2.count.reqd" 
set TARGETFILE_5 = "test-1.sub-2.word3.xml.reqd"   
set TARGETFILE_6 = "test-1.sub-2.word3.count.reqd" 

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

if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_4)) then
    echo "File $TARGETFILE_4 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_5)) then
    echo "File $TARGETFILE_5 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_6)) then
    echo "File $TARGETFILE_6 does not exist... aborting"
    exit
endif

# test with token file
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --token $TOKENFILE"
preprocess.pl $TESTFILE --token $TOKENFILE

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
diff word2.n.count $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word2.n.count and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.xml $TARGETFILE_5 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.xml and $TARGETFILE_5 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.count $TARGETFILE_6 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.count and $TARGETFILE_6 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n.xml
/bin/rm -f word1.n.count
/bin/rm -f word2.n.xml
/bin/rm -f word2.n.count
/bin/rm -f word3.n.xml
/bin/rm -f word3.n.count

# Subtest 3: testing with --useLexelt --token test-1.sub-3.token.txt 

echo "Subtest 3: Testing preprocess.pl with --useLexelt option"

set TESTFILE       = "test-5.xml"
set TOKENFILE      = "test-1.sub-3.token.txt"

# target files for subtest 3
set TARGETFILE_1 = "test-1.sub-3.word1.xml.reqd"   
set TARGETFILE_2 = "test-1.sub-3.word1.count.reqd" 
set TARGETFILE_3 = "test-1.sub-3.word2.xml.reqd"   
set TARGETFILE_4 = "test-1.sub-3.word2.count.reqd" 
set TARGETFILE_5 = "test-1.sub-3.word3.xml.reqd"   
set TARGETFILE_6 = "test-1.sub-3.word3.count.reqd" 

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

if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_4)) then
    echo "File $TARGETFILE_4 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_5)) then
    echo "File $TARGETFILE_5 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_6)) then
    echo "File $TARGETFILE_6 does not exist... aborting"
    exit
endif

# test with token file
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --useLexelt --token $TOKENFILE"
preprocess.pl $TESTFILE --useLexelt --token $TOKENFILE

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
diff word2.n.count $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word2.n.count and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.xml $TARGETFILE_5 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.xml and $TARGETFILE_5 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.count $TARGETFILE_6 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.count and $TARGETFILE_6 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n.xml
/bin/rm -f word1.n.count
/bin/rm -f word2.n.xml
/bin/rm -f word2.n.count
/bin/rm -f word3.n.xml
/bin/rm -f word3.n.count

# Subtest 4: testing with --useSenseid --token test-1.sub-3.token.txt 

echo "Subtest 4: Testing preprocess.pl with --useSenseid option"

set TESTFILE       = "test-5.xml"
set TOKENFILE      = "test-1.sub-3.token.txt"

# target files for subtest 4
set TARGETFILE_1 = "test-1.sub-4.word1.xml.reqd"   
set TARGETFILE_2 = "test-1.sub-4.word1.count.reqd" 
set TARGETFILE_3 = "test-1.sub-4.word2.xml.reqd"   
set TARGETFILE_4 = "test-1.sub-4.word2.count.reqd" 
set TARGETFILE_5 = "test-1.sub-4.word3.xml.reqd"   
set TARGETFILE_6 = "test-1.sub-4.word3.count.reqd" 

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

if (!(-e $TARGETFILE_3)) then
    echo "File $TARGETFILE_3 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_4)) then
    echo "File $TARGETFILE_4 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_5)) then
    echo "File $TARGETFILE_5 does not exist... aborting"
    exit
endif

if (!(-e $TARGETFILE_6)) then
    echo "File $TARGETFILE_6 does not exist... aborting"
    exit
endif

# test with token file
echo "Testing preprocess thusly: preprocess.pl $TESTFILE --useSenseid --token $TOKENFILE"
preprocess.pl $TESTFILE --useSenseid --token $TOKENFILE

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
diff word2.n.count $TARGETFILE_4 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word2.n.count and $TARGETFILE_4 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.xml $TARGETFILE_5 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.xml and $TARGETFILE_5 :"
    cat difference
endif
/bin/rm -f difference

# find diffs
diff word3.n.count $TARGETFILE_6 > difference
if (-z difference) then
    echo "Test OK"
else
    echo "Following differences exist between word3.n.count and $TARGETFILE_6 :"
    cat difference
endif
/bin/rm -f difference

/bin/rm -f word1.n.xml
/bin/rm -f word1.n.count
/bin/rm -f word2.n.xml
/bin/rm -f word2.n.count
/bin/rm -f word3.n.xml
/bin/rm -f word3.n.count

