###############################################################################

#				UNIT TEST B1 FOR filter.pl

###############################################################################

#       Test B1  -      
#			Checks the error condition in filter.pl program 
#			when both --rank and --percent are selected
#	Data	-	test-B1.data
#	Report  -	test-B1.report
#	Output	-	test-B1.reqd

echo "UNIT Test B1 -";
echo "		For Sense Filter Program filter.pl";
echo "Data- 		Source File test-B1.data";
echo "Report -	Frequency Report file test-B1.report";
echo "Output - 	Error message in file test-B1.reqd";
echo "		Checks the error condition in filter.pl when";
echo "		both --percent and --rank are selected.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --rank 3 --percent 13.33 test-B1.data test-B1.report >& test-B1.output

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-B1.output > t1
sort test-B1.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTB1
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "When Tested Against test-B1.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f test-B1.output t1 t2 variance 
#############################################################################

