###############################################################################

#			UNIT TEST A13 FOR filter.pl

###############################################################################

#       Test A13-       Checks filter.pl's nomulti and count
#	Data	-	test-A13.data
#	Count	-	test-A13.count
#	Report  -	test-A13.report
#	Output	-	test-A13.reqd

echo "UNIT Test A13 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A13.data";
echo "Count - 	test-A13.count";
echo "Frequency Report - ";
echo "		test-A13.report";
echo "Output - 	Filtered Data file from test-A13.reqd";
echo "Test -    	Checks filter.pl when nomulti and count options"
echo "		are provided and percent is set to 0";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --percent 0 --nomulti --count test-A13.count test-A13.data test-A13.report > test-A13.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A13.output > t1
sort test-A13.reqd > t2
diff -w t1 t2 > variance

sort test-A13.count.reqd > t1
sort test-A13.count.filtered > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA13
#=============================================================================
if(-z variance && -z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A13.reqd - ";
        cat variance
	echo "          When Tested Against test-A13.count.reqd - ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance variance1 test-A13.count.filtered test-A13.output

#############################################################################

