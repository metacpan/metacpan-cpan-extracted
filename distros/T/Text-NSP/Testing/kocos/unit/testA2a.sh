###############################################################################

#				UNIT TEST A2a FOR kocos.pl

###############################################################################

#       Test A2a  -     Checks if the program finds correct 1st order 
#			co-occurrences when co-occurrence graph has loops
#	Input	-	test-A2.count
#	Output	-	test-A2a.reqd

echo "UNIT Test A2a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A2.count";
echo "Output - 	Destination file from test-A2a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the co-occurrence graph has loops"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A2.count";
set Actual="test-A2a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line $TestInput > test-A2a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A2a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA2a
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

