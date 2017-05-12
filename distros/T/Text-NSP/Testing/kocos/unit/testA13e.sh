###############################################################################

#				UNIT TEST A13e FOR kocos.pl

###############################################################################

#       Test A13e  -    Checks if the program displays right message 
#			for 5th order co-occurrences 
#			co-occurrences when data contains puctuations 
#	Input	-	test-A13.count
#	Output	-	test-A13e.reqd

echo "UNIT Test A13e -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A13.count";
echo "Output - 	Destination file from test-A13e.reqd";
echo "Test -    	Checks if the program displays right message";
echo "		for 5th order co-occurrences when data contaings puctuations"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A13.count";
set Actual="test-A13e.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal mahanta --order 5 $TestInput > test-A13e1.output
 kocos.pl --regex test-A13.regex --order 5 $TestInput > test-A13e2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A13e1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A13e2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA13e
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal mahanta ";
        cat variance1
	echo "		When Tested for --regex test-A13.regex";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

