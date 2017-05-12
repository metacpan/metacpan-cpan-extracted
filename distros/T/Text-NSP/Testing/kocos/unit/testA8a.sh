###############################################################################

#				UNIT TEST A8a FOR kocos.pl

###############################################################################

#       Test A8a  -     Checks if the program finds correct 1st order 
#			co-occurrences when target word is specified as a regex 
#	Input	-	test-A8.count
#	Output	-	test-A8a.reqd

echo "UNIT Test A8a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A8.count";
echo "Output - 	Destination file from test-A8a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the target word is specified via regex"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A8.count";
set Actual="test-A8a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A8.regex $TestInput > test-A8a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A8a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA8a
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

