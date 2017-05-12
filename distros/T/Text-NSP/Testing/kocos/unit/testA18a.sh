###############################################################################

#				UNIT TEST A18a FOR kocos.pl

###############################################################################

#       Test A18a  -    Checks if the program finds correct 1st order 
#			co-occurrences when data contains phone nos and emails 
#	Input	-	test-A18.count
#	Output	-	test-A18a.reqd

echo "UNIT Test A18a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A18.count";
echo "Output - 	Destination file from test-A18a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when data contains phone nos and emails";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A18.count";
set Actual="test-A18a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A18.regex $TestInput > test-A18a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A18a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA18a
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --regex test-A18.regex ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

