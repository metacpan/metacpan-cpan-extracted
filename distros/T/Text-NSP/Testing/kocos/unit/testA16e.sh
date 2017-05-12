###############################################################################

#				UNIT TEST A16e FOR kocos.pl

###############################################################################

#       Test A16e  -    Checks if the program displays right message 
#			for 5th order co-occurrences 
#			when tokens include punctuations 
#	Input	-	test-A16.count
#	Output	-	test-A16e.reqd

echo "UNIT Test A16e -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A16.count";
echo "Output - 	Destination file from test-A16e.reqd";
echo "Test -    	Checks if the program displays right message";
echo "		for 5th order co-occurrences when tokens include punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A16.count";
set Actual="test-A16e.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal on --order 5 $TestInput > test-A16e1.output
 kocos.pl --regex test-A16.regex --order 5 $TestInput > test-A16e2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A16e1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A16e2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA16e
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal on ";
        cat variance1
	echo "		When Tested for --regex test-A16.regex";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

