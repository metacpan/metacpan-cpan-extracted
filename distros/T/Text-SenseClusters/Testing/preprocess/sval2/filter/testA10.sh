###############################################################################

#			UNIT TEST A10 FOR filter.pl

###############################################################################

#       Test A10-       Checks filter.pl when count file is also tobe 
#			filtered and nomulti is chosen
#	Data	-	test-A10.data
#	Report  -	test-A10.report
#	Count	-	test-A10.count
#	Output	-	test-A10.reqd
#	Filtered Count
#		-	test-A10.count.reqd

echo "UNIT Test A10 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A10.data";
echo "Frequency Report - ";
echo "		test-A10.report";
echo "Count -		test-A10.count";
echo "Output - 	Filtered Data file from test-A10.reqd";
echo "Filtered Count -";
echo "		test-A10.count.reqd";
echo "Test -    	Checks filter.pl when corresponding count file";
echo "		is given for filtering and nomulti is chosen.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --nomulti --rank 3 --count test-A10.count test-A10.data test-A10.report > test-A10.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A10.output > t1
sort test-A10.reqd > t2
diff -w t1 t2 > variance

sort test-A10.count.reqd > t3
sort test-A10.count.filtered > t4
diff -w t3 t4 > variance1
#=============================================================================
#				RESULTS OF TESTA10
#=============================================================================
if(-z variance && -z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A10.reqd - ";
        cat variance
	echo "          When Tested Against test-A10.count.reqd - ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance t3 t4 variance1 test-A10.count.filtered test-A10.output

#############################################################################

