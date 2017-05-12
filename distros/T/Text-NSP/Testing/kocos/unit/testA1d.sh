###############################################################################

#				UNIT TEST A1d FOR kocos.pl

###############################################################################

#       Test A1d  -     Checks if the program shows right message when 
#			no co-occurrences occur at the specified order
#			and when co-occurrence graph is a tree
#	Input	-	test-A1.count
#	Output	-	test-A1d.reqd

echo "UNIT Test A1d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A1.count";
echo "Output - 	Destination file from test-A1d.reqd";
echo "Test -    	Checks if the program shows right message when";
echo "		no co-occurrences occur at the specified order"; 

#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A1.count";
set Actual="test-A1d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 4 $TestInput > test-A1d.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A1d.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA1d
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

