###############################################################################

#			UNIT TEST A7 FOR filter.pl

###############################################################################

#       Test A7 -       Checks filter.pl when count file is also tobe 
#			filtered 
#	Data	-	test-A7.data
#	Report  -	test-A7.report
#	Count	-	test-A7.count
#	Output	-	test-A7.reqd
#	Filtered Count
#		-	test-A7.count.reqd

echo "UNIT Test A7 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A7.data";
echo "Frequency Report - ";
echo "		test-A7.report";
echo "Count -		test-A7.count";
echo "Output - 	Filtered Data file from test-A7.reqd";
echo "Filtered Count -";
echo "		test-A7.count.reqd";
echo "Test -    	Checks filter.pl when corresponding count file";
echo "		is given for filtering.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --rank 3 --count test-A7.count test-A7.data test-A7.report > test-A7.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A7.output > t1
sort test-A7.reqd > t2
diff -w t1 t2 > variance

sort test-A7.count.reqd > t3
sort test-A7.count.filtered > t4
diff -w t3 t4 > variance1
#=============================================================================
#				RESULTS OF TESTA7
#=============================================================================
if(-z variance && -z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A7.reqd - ";
        cat variance
	echo "          When Tested Against test-A7.count.reqd - ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance t3 t4 variance1 test-A7.count.filtered test-A7.output

#############################################################################

