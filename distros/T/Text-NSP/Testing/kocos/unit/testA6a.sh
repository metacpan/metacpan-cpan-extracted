###############################################################################

#				UNIT TEST A6a FOR kocos.pl

###############################################################################

#       Test A6a  -     Checks if the program finds correct 1st order 
#			co-occurrences when co-occurrence graph is a chain with
#			two alternate loops
#	Input	-	test-A6.count
#	Output	-	test-A6a.reqd

echo "UNIT Test A6a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A6.count";
echo "Output - 	Destination file from test-A6a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the co-occurrence graph is a chain";
echo "		with two alternate loops"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A6.count";
set Actual="test-A6a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line $TestInput > test-A6a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A6a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA6a 
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

