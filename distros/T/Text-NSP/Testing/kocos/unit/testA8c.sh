###############################################################################

#				UNIT TEST A8c FOR kocos.pl

###############################################################################

#       Test A8c  -     Checks if the program finds correct 3rd order 
#			co-occurrences when target word is specified as a regex 
#	Input	-	test-A8.count
#	Output	-	test-A8c.reqd

echo "UNIT Test A8c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A8.count";
echo "Output - 	Destination file from test-A8c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the target word is specified as a regex"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A8.count";
set Actual="test-A8c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A8.regex --order 3 $TestInput > test-A8c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A8c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA8c
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

