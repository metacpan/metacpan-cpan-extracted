###############################################################################

#			UNIT TEST A11 FOR filter.pl

###############################################################################

#       Test A11-       Checks filter.pl's default filter  
#	Data	-	test-A11.data
#	Report  -	test-A11.report
#	Output	-	test-A11.reqd

echo "UNIT Test A11 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A11.data";
echo "Frequency Report - ";
echo "		test-A11.report";
echo "Output - 	Filtered Data file from test-A11.reqd";
echo "Test -    	Checks filter.pl's default filter (percent=1%";
echo "		to remove senses occurring below 1%) when no Filters are";
echo "		selected but --nomulti is chosen.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --nomulti test-A11.data test-A11.report > test-A11.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A11.output > t1
sort test-A11.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA11
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A11.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A11.output

#############################################################################

