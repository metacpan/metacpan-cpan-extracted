###############################################################################

#				UNIT TEST B1 FOR kocos.pl

###############################################################################

#       Test B1  -    	Error test when order < 1 
#	Input	-	test-B1.count
#	Output	-	test-B1.reqd

echo "UNIT Test B1 -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-B1.count";
echo "Output - 	Destination file from test-B1.reqd";
echo "Test -    	Error test when order < 1";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-B1.count";
set Actual="test-B1.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order -1 $TestInput >& test-B1.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-B1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTB1
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

