###############################################################################

#				UNIT TEST A9b FOR kocos.pl

###############################################################################

#       Test A9b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when target word is a regex from file 
#	Input	-	test-A9.count
#	Output	-	test-A9b.reqd

echo "UNIT Test A9b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A9.count";
echo "Output - 	Destination file from test-A9b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the target word is a regex from file";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A9.count";
set Actual="test-A9b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A9.regex --order 2 $TestInput > test-A9b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A9b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA9b
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

