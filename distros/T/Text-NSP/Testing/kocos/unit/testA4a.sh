###############################################################################

#				UNIT TEST A4a FOR kocos.pl

###############################################################################

#       Test A4a  -     Checks if the program finds correct 1st order 
#			co-occurrences when co-occurrence graph is a complete
#			bipartitie of order 3  
#	Input	-	test-A4.count
#	Output	-	test-A4a.reqd

echo "UNIT Test A4a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A4.count";
echo "Output - 	Destination file from test-A4a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the co-occurrence graph is a complete";
echo "		bipartite of order 3"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A4.count";
set Actual="test-A4a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line $TestInput > test-A4a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A4a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA4a
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

