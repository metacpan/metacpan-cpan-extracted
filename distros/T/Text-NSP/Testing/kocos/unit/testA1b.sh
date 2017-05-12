###############################################################################

#				UNIT TEST A1b FOR kocos.pl

###############################################################################

#       Test A1b  -     Checks if the program finds correct 2nd order 
#			co-occurrences when co-occurrence graph is a tree
#	Input	-	test-A1.count
#	Output	-	test-A1b.reqd

echo "UNIT Test A1b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A1.count";
echo "Output - 	Destination file from test-A1b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when the co-occurrence graph is a tree"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A1.count";
set Actual="test-A1b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 2 $TestInput > test-A1b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A1b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA1b
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

