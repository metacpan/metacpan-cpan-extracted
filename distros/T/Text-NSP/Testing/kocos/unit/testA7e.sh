###############################################################################

#				UNIT TEST A7e FOR kocos.pl

###############################################################################

#       Test A7e  -     Checks if the program shows right message when 
#			no co-occurrences occur at the specified order
#			and when co-occurrence graph has a zigzag form 
#	Input	-	test-A7.count
#	Output	-	test-A7e.reqd

echo "UNIT Test A7e -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A7.count";
echo "Output - 	Destination file from test-A7e.reqd";
echo "Test -    	Checks if the program shows right message when";
echo "		no co-occurrences occur at the specified order"; 

#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A7.count";
set Actual="test-A7e.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 5 $TestInput > test-A7e.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A7e.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA7e
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against $Actual - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance

#############################################################################

