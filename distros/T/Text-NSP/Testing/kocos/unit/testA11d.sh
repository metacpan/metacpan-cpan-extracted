###############################################################################

#				UNIT TEST A11d FOR kocos.pl

###############################################################################

#       Test A11d  -    Checks if the program finds correct 4th order 
#			co-occurrences when target word is /\./ 
#	Input	-	test-A11.count
#	Output	-	test-A11d.reqd

echo "UNIT Test A11d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A11.count";
echo "Output - 	Destination file from test-A11d.reqd";
echo "Test -    	Checks if the program finds correct 4th order";
echo "		co-occurrences when the target word is /\./";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A11.count";
set Actual="test-A11d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A11.regex --order 4 $TestInput > test-A11d.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A11d.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA11d
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "		When Tested for --regex test-A11.regex";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

