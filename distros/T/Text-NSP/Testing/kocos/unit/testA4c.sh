###############################################################################

#				UNIT TEST A4c FOR kocos.pl

###############################################################################

#       Test A4c  -     Checks if the program finds correct 3rd order 
#			co-occurrences when co-occurrence graph is a complete 
#			bipartite of order 3  
#	Input	-	test-A4.count
#	Output	-	test-A4c.reqd

echo "UNIT Test A4c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A4.count";
echo "Output - 	Destination file from test-A4c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the co-occurrence graph is a complete";
echo "		bipartite of order 3"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A4.count";
set Actual="test-A4c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 3 $TestInput > test-A4c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A4c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA4c
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

