###############################################################################

#				UNIT TEST A8 FOR filter.pl

###############################################################################

#       Test A8  -      
#			Checks the condition in filter.pl program 
#			a sense tag in data doesn't appear in Frequency Report
#	Data	-	test-A8.data
#	Report  -	test-A8.report
#	Output	-	test-A8.reqd

echo "UNIT Test A8 -";
echo "		For Sense Filter Program filter.pl";
echo "Data- 		Source File test-A8.data";
echo "Report -	Frequency Report file test-A8.report";
echo "Output - 	File test-A8.reqd";
echo "		Checks the condition in filter.pl when a";
echo "		sense tag in the data file is not listed in the Frequency Report";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl test-A8.data test-A8.report > test-A8.output

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A8.output > t1
sort test-A8.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA8
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "When Tested Against test-A8.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A8.output
#############################################################################

