###############################################################################

#				UNIT TEST B2 FOR kocos.pl

###############################################################################

#       Test B2  -    	Bigram file not valid
#	Input	-	test-B2.count
#	Output	-	test-B2.reqd

echo "UNIT Test B2 -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-B2.count";
echo "Output - 	Destination file from test-B2.reqd";
echo "Test -    	Error test when bigram file is not valid.";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-B2.count";
set Actual="test-B2.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 3 $TestInput >& test-B2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-B2.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTB2 
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against $Actual - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance

#############################################################################

