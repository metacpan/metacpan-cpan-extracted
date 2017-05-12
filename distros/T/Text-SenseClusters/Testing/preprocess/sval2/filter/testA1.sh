###############################################################################

#			UNIT TEST A1 FOR filter.pl

###############################################################################

#       Test A1  -      Checks filter.pl for --rank filter 
#	Data	-	test-A1.data
#	Report  -	test-A1.report
#	Output	-	test-A1.reqd

echo "UNIT Test A1 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A1.data";
echo "Frequency Report - ";
echo "		test-A1.report";
echo "Output - 	Filtered Data file from test-A1.reqd";
echo "Test -    	Checks filter.pl's --rank R filter to select";
echo "		Top R most frequent senses.";


#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --rank 3 test-A1.data test-A1.report > test-A1.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A1.output > t1
sort test-A1.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA1
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A1.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1.output

#############################################################################

