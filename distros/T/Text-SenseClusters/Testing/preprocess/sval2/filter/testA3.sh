###############################################################################

#			UNIT TEST A3 FOR filter.pl

###############################################################################

#       Test A3 -       Checks filter.pl for --percent filter 
#	Data	-	test-A3.data
#	Report  -	test-A3.report
#	Output	-	test-A3.reqd

echo "UNIT Test A3 -";
echo "		For Sense Filter Program filter.pl";
echo "Data - 		Source file from test-A3.data";
echo "Frequency Report - ";
echo "		test-A3.report";
echo "Output - 	Filtered Data file from test-A3.reqd";
echo "Test -    	Checks filter.pl's --percent P filter to select";
echo "		senses with percent P% or more.";


#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 filter.pl --percent 10 test-A3.data test-A3.report > test-A3.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A3.output > t1
sort test-A3.reqd > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA3
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against test-A3.reqd - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3.output

#############################################################################

