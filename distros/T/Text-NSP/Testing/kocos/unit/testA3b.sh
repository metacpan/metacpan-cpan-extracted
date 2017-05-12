###############################################################################

#				UNIT TEST A3b FOR kocos.pl

###############################################################################

#       Test A3b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when co-occurrence graph is a 4 fold sqaure 
#	Input	-	test-A3.count
#	Output	-	test-A3b.reqd

echo "UNIT Test A3b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A3.count";
echo "Output - 	Destination file from test-A3b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the co-occurrence graph is a 4 fold square"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A3.count";
set Actual="test-A3b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 2 $TestInput > test-A3b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A3b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA3b
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

