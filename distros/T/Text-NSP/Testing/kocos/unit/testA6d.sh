###############################################################################

#				UNIT TEST A6d FOR kocos.pl

###############################################################################

#       Test A6d  -     Checks if the program finds correct 4th order 
#			co-occurrences when co-occurrence graph is a chain with
#			two alternate loops
#	Input	-	test-A6.count
#	Output	-	test-A6d.reqd

echo "UNIT Test A6d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A6.count";
echo "Output - 	Destination file from test-A6d.reqd";
echo "Test -    	Checks if the program finds correct 4th order";
echo "		co-occurrences when the co-occurrence graph is a chain";
echo "		with two alternate loops"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A6.count";
set Actual="test-A6d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 4 $TestInput > test-A6d.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A6d.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA6d 
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

