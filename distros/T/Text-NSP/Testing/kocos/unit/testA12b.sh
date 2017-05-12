###############################################################################

#				UNIT TEST A12b FOR kocos.pl

###############################################################################

#       Test A12b  -    Checks if the program finds correct 2nd order 
#			co-occurrences when target words end in 'nA' 
#	Input	-	test-A12.count
#	Output	-	test-A12b.reqd

echo "UNIT Test A12b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A12.count";
echo "Output - 	Destination file from test-A12b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the target words end in nA ";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A12.count";
set Actual="test-A12b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A12.regex --order 2 $TestInput > test-A12b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A12b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA12b
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "		When Tested for --regex test-A12.regex";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

