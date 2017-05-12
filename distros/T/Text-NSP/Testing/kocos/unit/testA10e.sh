###############################################################################

#				UNIT TEST A10e FOR kocos.pl

###############################################################################

#       Test A10e  -    Checks if the program displays right message 
#			for 5th order co-occurrences 
#			when target word is , 
#	Input	-	test-A10.count
#	Output	-	test-A10e.reqd

echo "UNIT Test A10e -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A10.count";
echo "Output - 	Destination file from test-A10e.reqd";
echo "Test -    	Checks if the program displays right message";
echo "		for 5th order co-occurrences when the target word is ,";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A10.count";
set Actual="test-A10e.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal , --order 5 $TestInput > test-A10e1.output
 kocos.pl --regex test-A10.regex --order 5 $TestInput > test-A10e2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A10e1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A10e2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA10e
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal , ";
        cat variance1
	echo "		When Tested for --regex test-A10.regex";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

