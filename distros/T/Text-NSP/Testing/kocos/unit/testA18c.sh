###############################################################################

#			UNIT TEST A18c FOR kocos.pl

###############################################################################

#       Test A18c  -    Checks if the program finds correct 3rd order 
#			co-occurrences when data contains phone nos and emails 
#	Input	-	test-A18.count
#	Output	-	test-A18c.reqd

echo "UNIT Test A18c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A18.count";
echo "Output - 	Destination file from test-A18c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when data contains phone nos and emails";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A18.count";
set Actual="test-A18c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A18.regex --order 3 $TestInput > test-A18c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A18c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA18c
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "          When Tested for --regex test-A18.regex ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

