###############################################################################

#				UNIT TEST B2 FOR filter.pl

###############################################################################

#       Test B2  -      
#			Checks the error condition in filter.pl program 
#			Frequency Report File doesn't follow the required format
#	Data	-	test-B2.data
#	Report  -	test-B2.report
#	Output	-	test-B2.reqd

echo "UNIT Test B2 -";
echo "		For Sense Filter Program filter.pl";
echo "Data- 		Source File test-B2.data";
echo "Report -	Frequency Report file test-B2.report";
echo "Output - 	Error message in file test-B2.reqd";
echo "		Checks the error condition in filter.pl when";
echo "		Frequency Report doesn't follow the required format.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl test-B2.data test-B2.report >& test-B2.output

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-B2.output > t1
sort test-B2.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTB2
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "When Tested Against test-B2.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-B2.output 
#############################################################################

