###############################################################################

#			UNIT TEST A2 FOR filter.pl

###############################################################################

#       Test A2 -       Checks filter.pl's default filter  
#	Data	-	test-A2.data
#	Report  -	test-A2.report
#	Output	-	test-A2.reqd

echo "UNIT Test A2 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A2.data";
echo "Frequency Report - ";
echo "		test-A2.report";
echo "Output - 	Filtered Data file from test-A2.reqd";
echo "Test -    	Checks filter.pl's default filter (frequency=1%";
echo "		to remove senses occurring below 1%) when no Filters are";
echo "		selected.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl test-A2.data test-A2.report > test-A2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A2.output > t1
sort test-A2.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA2
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A2.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A2.output

#############################################################################

