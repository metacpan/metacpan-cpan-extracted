###############################################################################

#				UNIT TEST A18b FOR kocos.pl

###############################################################################

#       Test A18b  -    Checks if the program finds correct 2nd order 
#			co-occurrences when data contains phone nos and emails 
#	Input	-	test-A18.count
#	Output	-	test-A18b.reqd

echo "UNIT Test A18b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A18.count";
echo "Output - 	Destination file from test-A18b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when data contains phone nos and emails";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A18.count";
set Actual="test-A18b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A18.regex --order 2 $TestInput > test-A18b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A18b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA18b
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "		When Tested for --regex test-A18.regex";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

