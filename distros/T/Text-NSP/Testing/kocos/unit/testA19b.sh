###############################################################################

#				UNIT TEST A19b FOR kocos.pl

###############################################################################

#       Test A19b  -    Checks if the program finds correct 2nd order 
#			co-occurrences from Hindi transliterated data 
#	Input	-	test-A19.count
#	Output	-	test-A19b.reqd

echo "UNIT Test A19b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A19.count";
echo "Output - 	Destination file from test-A19b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences from Hindi data containing puctuations"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A19.count";
set Actual="test-A19b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal karanA --order 2 $TestInput > test-A19b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A19b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA19b
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal karanA- ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance

#############################################################################

