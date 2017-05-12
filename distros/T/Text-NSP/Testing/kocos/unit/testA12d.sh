###############################################################################

#				UNIT TEST A12d FOR kocos.pl

###############################################################################

#       Test A12d  -    Checks if the program finds correct 4th order 
#			co-occurrences when target words end in nA
#	Input	-	test-A12.count
#	Output	-	test-A12d.reqd

echo "UNIT Test A12d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A12.count";
echo "Output - 	Destination file from test-A12d.reqd";
echo "Test -    	Checks if the program finds correct 4th order";
echo "		co-occurrences when the target words end in nA";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A12.count";
set Actual="test-A12d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A12.regex --order 4 $TestInput > test-A12d.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A12d.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA12d
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

