###############################################################################

#				UNIT TEST A3a FOR kocos.pl

###############################################################################

#       Test A3a  -     Checks if the program finds correct 1st order 
#			co-occurrences when co-occurrence graph is a 4 folded
#			square 
#	Input	-	test-A3.count
#	Output	-	test-A3a.reqd

echo "UNIT Test A3a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A3.count";
echo "Output - 	Destination file from test-A3a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the co-occurrence graph is a 4 fold square"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A3.count";
set Actual="test-A3a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line $TestInput > test-A3a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A3a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA3a
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

