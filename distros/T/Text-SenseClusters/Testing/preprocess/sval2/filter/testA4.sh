###############################################################################

#			UNIT TEST A4 FOR filter.pl

###############################################################################

#       Test A4 -       Checks filter.pl for boundary condition on
#			--percent filter 
#	Data	-	test-A4.data
#	Report  -	test-A4.report
#	Output	-	test-A4.reqd

echo "UNIT Test A4 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A4.data";
echo "Frequency Report - ";
echo "		test-A4.report";
echo "Output - 	Filtered Data file from test-A4.reqd";
echo "Test -    	Checks the boundary condition on --percent option";


#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --percent 13.33 test-A4.data test-A4.report > test-A4.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A4.output > t1
sort test-A4.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA4
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A4.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A4.output

#############################################################################

