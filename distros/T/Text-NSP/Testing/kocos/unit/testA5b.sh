###############################################################################

#				UNIT TEST A5b FOR kocos.pl

###############################################################################

#       Test A5b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when co-occurrence graph is a cycle
#	Input	-	test-A5.count
#	Output	-	test-A5b.reqd

echo "UNIT Test A5b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A5.count";
echo "Output - 	Destination file from test-A5b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the co-occurrence graph is a cycle"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A5.count";
set Actual="test-A5b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 2 $TestInput > test-A5b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A5b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA5b 
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

