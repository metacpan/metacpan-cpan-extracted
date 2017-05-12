###############################################################################

#				UNIT TEST A2b FOR kocos.pl

###############################################################################

#       Test A2b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when co-occurrence graph has loops 
#	Input	-	test-A2.count
#	Output	-	test-A2b.reqd

echo "UNIT Test A2b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A2.count";
echo "Output - 	Destination file from test-A2b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the co-occurrence graph has loops"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A2.count";
set Actual="test-A2b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 2 $TestInput > test-A2b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A2b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA2b
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

