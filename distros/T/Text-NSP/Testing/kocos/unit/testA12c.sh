###############################################################################

#			UNIT TEST A12c FOR kocos.pl

###############################################################################

#       Test A12c  -    Checks if the program finds correct 3rd order 
#			co-occurrences when target words end with nA 
#	Input	-	test-A12.count
#	Output	-	test-A12c.reqd

echo "UNIT Test A12c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A12.count";
echo "Output - 	Destination file from test-A12c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the target words end with nA";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A12.count";
set Actual="test-A12c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A12.regex --order 3 $TestInput > test-A12c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A12c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA12c
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "          When Tested for --regex test-A12.regex ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

