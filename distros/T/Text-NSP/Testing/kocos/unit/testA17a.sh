###############################################################################

#				UNIT TEST A17a FOR kocos.pl

###############################################################################

#       Test A17a  -     Checks if the program finds correct 1st order 
#			co-occurrences from some general text 
#	Input	-	test-A17.count
#	Output	-	test-A17a.reqd

echo "UNIT Test A17a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A17.count";
echo "Output - 	Destination file from test-A17a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences from some general text."; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A17.count";
set Actual="test-A17a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal GNU $TestInput > test-A17a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A17a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA17a
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal GNU - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance

#############################################################################

