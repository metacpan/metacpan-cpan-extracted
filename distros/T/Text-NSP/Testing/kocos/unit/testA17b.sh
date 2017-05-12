###############################################################################

#				UNIT TEST A17b FOR kocos.pl

###############################################################################

#       Test A17b  -     Checks if the program finds correct 2nd order 
#			co-occurrences from some real text data 
#	Input	-	test-A17.count
#	Output	-	test-A17b.reqd

echo "UNIT Test A17b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A17.count";
echo "Output - 	Destination file from test-A17b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences from some real text data"; 


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A17.count";
set Actual="test-A17b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal GNU --order 2 $TestInput > test-A17b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A17b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA17b
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

