###############################################################################

#				UNIT TEST A19a FOR kocos.pl

###############################################################################

#       Test A19a  -    Checks if the program finds correct 1st order 
#			co-occurrences from data containing puctuations 
#	Input	-	test-A19.count
#	Output	-	test-A19a.reqd

echo "UNIT Test A19a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A19.count";
echo "Output - 	Destination file from test-A19a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences from Hindi text containing puctuations."; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A19.count";
set Actual="test-A19a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal karanA $TestInput > test-A19a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A19a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA19a
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal karanA - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance

#############################################################################

