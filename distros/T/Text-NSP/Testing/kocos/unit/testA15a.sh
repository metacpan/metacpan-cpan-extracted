###############################################################################

#				UNIT TEST A15a FOR kocos.pl

###############################################################################

#       Test A15a  -    Checks if the program finds correct 1st order 
#			co-occurrences when each tokens is a bigram
#	Input	-	test-A15.count
#	Output	-	test-A15a.reqd

echo "UNIT Test A15a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A15.count";
echo "Output - 	Destination file from test-A15a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when each token is a bigram.";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A15.count";
set Actual="test-A15a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal "alan bond" $TestInput > test-A15a1.output
 kocos.pl --regex test-A15.regex $TestInput > test-A15a2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A15a1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A15a2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA15a
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal "alan bond" ";
        cat variance1
	echo "          When Tested for --regex test-A15.regex ";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

