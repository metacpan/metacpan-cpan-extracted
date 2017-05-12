#!/bin/csh -f

# shell program to test nsp2regex.pl

# first the token file
set TOKENFILE = "token.txt"

# now the 6 sub tests
foreach number (1 2 3 4 5 6 7)

    echo "Subtest $number : "

    set TESTFILE       = "sub-$number.source"
    set TARGETFILE_1   = "sub-$number.source.reqd"
    set TARGETFILE_2   = "sub-$number.token.reqd"

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
    
    # run the test without the token file
    echo "Testing nsp2regex thusly: nsp2regex.pl $TESTFILE > out"
    nsp2regex.pl $TESTFILE > out
    
    # find diff
    diff out $TARGETFILE_1 > difference
    if (-z difference) then
	echo "Test OK"
    else
	echo "Following differences exist between out and $TARGETFILE_1 :"
	cat difference
    endif
    /bin/rm -f difference
    /bin/rm -f out 
    
    # run the test with the token file
    echo "Testing nsp2regex thusly: nsp2regex.pl $TESTFILE --token $TOKENFILE > out"
    nsp2regex.pl $TESTFILE --token $TOKENFILE > out
    
    # find diff
    diff out $TARGETFILE_2 > difference
    if (-z difference) then
	echo "Test OK"
    else
	echo "Following differences exist between out and $TARGETFILE_1 :"
    cat difference
    endif
    /bin/rm -f difference
    /bin/rm -f out 

end 

