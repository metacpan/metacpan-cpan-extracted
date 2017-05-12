###############################################################################

#				UNIT TEST A9c FOR kocos.pl

###############################################################################

#       Test A9c  -     Checks if the program finds correct 3rd order 
#			co-occurrences when target word is a regex from file 
#	Input	-	test-A9.count
#	Output	-	test-A9c.reqd

echo "UNIT Test A9c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A9.count";
echo "Output - 	Destination file from test-A9c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the target word is a regex from file";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A9.count";
set Actual="test-A9c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A9.regex --order 3 $TestInput > test-A9c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A9c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA9c
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

