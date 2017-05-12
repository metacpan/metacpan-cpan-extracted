###############################################################################

#				UNIT TEST A4b FOR kocos.pl

###############################################################################

#       Test A4b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when co-occurrence graph is a complete 
#			bipartite of order 3  
#	Input	-	test-A4.count
#	Output	-	test-A4b.reqd

echo "UNIT Test A4b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A4.count";
echo "Output - 	Destination file from test-A4b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the co-occurrence graph is a complete";
echo "		bipartite of order 3"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A4.count";
set Actual="test-A4b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 2 $TestInput > test-A4b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A4b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA4b
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

