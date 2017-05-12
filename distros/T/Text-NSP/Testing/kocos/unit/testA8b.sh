###############################################################################

#				UNIT TEST A8b FOR kocos.pl

###############################################################################

#       Test A8b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when target word is specified via regex 
#	Input	-	test-A8.count
#	Output	-	test-A8b.reqd

echo "UNIT Test A8b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A8.count";
echo "Output - 	Destination file from test-A8b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when target word is specified as a regex"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A8.count";
set Actual="test-A8b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A8.regex --order 2 $TestInput > test-A8b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A8b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA8b
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

