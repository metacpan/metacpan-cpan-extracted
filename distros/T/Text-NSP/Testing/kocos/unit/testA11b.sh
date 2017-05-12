###############################################################################

#				UNIT TEST A11b FOR kocos.pl

###############################################################################

#       Test A11b  -    Checks if the program finds correct 2nd order 
#			co-occurrences when target word is /\./ 
#	Input	-	test-A11.count
#	Output	-	test-A11b.reqd

echo "UNIT Test A11b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A11.count";
echo "Output - 	Destination file from test-A11b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the target word is /\./";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A11.count";
set Actual="test-A11b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A11.regex --order 2 $TestInput > test-A11b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A11b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA11b
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "		When Tested for --regex test-A11.regex";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

