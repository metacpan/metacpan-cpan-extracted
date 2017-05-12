###############################################################################

#			UNIT TEST A5 FOR filter.pl

###############################################################################

#       Test A5 -       Checks filter.pl when there are ties on ranks 
#	Data	-	test-A5.data
#	Report  -	test-A5.report
#	Output	-	test-A5.reqd

echo "UNIT Test A5 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A5.data";
echo "Frequency Report - ";
echo "		test-A5.report";
echo "Output - 	Filtered Data file from test-A5.reqd";
echo "Test -    	Checks filter.pl's --rank R filter when there";
echo "		are ties on ranks at or below R.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --rank 5 test-A5.data test-A5.report > test-A5.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A5.output > t1
sort test-A5.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA5
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A5.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A5.output

#############################################################################

