###############################################################################

#				UNIT TEST A8d FOR kocos.pl

###############################################################################

#       Test A8d  -     Checks if the program shows right message when 
#			no co-occurrences occur at the specified order
#			and when co-occurrence graph is a tree
#	Input	-	test-A8.count
#	Output	-	test-A8d.reqd

echo "UNIT Test A8d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A8.count";
echo "Output - 	Destination file from test-A8d.reqd";
echo "Test -    	Checks if the program shows right message when";
echo "		no co-occurrences occur at the specified order"; 

#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A8.count";
set Actual="test-A8d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A8.regex --order 4 $TestInput > test-A8d.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A8d.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA8d
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

