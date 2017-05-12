###############################################################################

#				UNIT TEST A1c FOR kocos.pl

###############################################################################

#       Test A1c  -     Checks if the program finds correct 3rd order 
#			co-occurrences when co-occurrence graph is a tree
#	Input	-	test-A1.count
#	Output	-	test-A1c.reqd

echo "UNIT Test A1c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A1.count";
echo "Output - 	Destination file from test-A1c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the co-occurrence graph is a tree"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A1.count";
set Actual="test-A1c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 3 $TestInput > test-A1c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A1c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA1c
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

