###############################################################################

#			UNIT TEST A6 FOR filter.pl

###############################################################################

#       Test A6 -       Checks filter.pl when extra tags appear in source 
#	Data	-	test-A6.data
#	Report  -	test-A6.report
#	Output	-	test-A6.reqd

echo "UNIT Test A6 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A6.data";
echo "Frequency Report - ";
echo "		test-A6.report";
echo "Output - 	Filtered Data file from test-A6.reqd";
echo "Test -    	Checks filter.pl when extra tags appear in data.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --rank 5 test-A6.data test-A6.report > test-A6.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A6.output > t1
sort test-A6.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA6
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A6.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A6.output

#############################################################################

