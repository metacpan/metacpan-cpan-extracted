###############################################################################

#			UNIT TEST A12 FOR filter.pl

###############################################################################

#       Test A12-       Checks filter.pl's nomulti 
#	Data	-	test-A12.data
#	Report  -	test-A12.report
#	Output	-	test-A12.reqd

echo "UNIT Test A12 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A12.data";
echo "Frequency Report - ";
echo "		test-A12.report";
echo "Output - 	Filtered Data file from test-A12.reqd";
echo "Test -    	Checks filter.pl when percent is set to 0 and ";
echo "		--nomulti is selected.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --percent 0 --nomulti test-A12.data test-A12.report > test-A12.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A12.output > t1
sort test-A12.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA12
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A12.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A12.output

#############################################################################

