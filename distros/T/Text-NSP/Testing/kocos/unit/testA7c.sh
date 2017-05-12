###############################################################################

#				UNIT TEST A7c FOR kocos.pl

###############################################################################

#       Test A7c  -     Checks if the program finds correct 3rd order 
#			co-occurrences when co-occurrence graph has zigzag form 
#	Input	-	test-A7.count
#	Output	-	test-A7c.reqd

echo "UNIT Test A7c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A7.count";
echo "Output - 	Destination file from test-A7c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the co-occurrence graph has a zigzag shape"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A7.count";
set Actual="test-A7c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal line --order 3 $TestInput > test-A7c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A7c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA7c 
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

