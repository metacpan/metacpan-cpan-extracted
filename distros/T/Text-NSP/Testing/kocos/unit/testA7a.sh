###############################################################################

#				UNIT TEST A7a FOR kocos.pl

###############################################################################

#       Test A7a  -     Checks if the program finds correct 1st order 
#			co-occurrences when co-occurrence graph has zigzag form 
#	Input	-	test-A7.count
#	Output	-	test-A7a.reqd

echo "UNIT Test A7a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A7.count";
echo "Output - 	Destination file from test-A7a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the co-occurrence graph has a zigzag shape"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A7.count";
set Actual="test-A7a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line $TestInput > test-A7a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A7a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA7a 
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

