###############################################################################

#			UNIT TEST A9 FOR filter.pl

###############################################################################

#       Test A9 -      Checks filter.pl for --nomulti filter 
#	Data	-	test-A9.data
#	Report  -	test-A9.report
#	Output	-	test-A9.reqd

echo "UNIT Test A9 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A9.data";
echo "Frequency Report - ";
echo "		test-A9.report";
echo "Output - 	Filtered Data file from test-A9.reqd";
echo "Test -    	Checks filter.pl's --nomulti option";


#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --rank 5 --nomulti test-A9.data test-A9.report > test-A9.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A9.output > t1
sort test-A9.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA9
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A9.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A9.output

#############################################################################

