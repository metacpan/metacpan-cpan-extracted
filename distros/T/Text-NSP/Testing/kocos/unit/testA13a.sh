###############################################################################

#				UNIT TEST A13a FOR kocos.pl

###############################################################################

#       Test A13a  -    Checks if the program finds correct 1st order 
#			co-occurrences when data contains punctuations 
#	Input	-	test-A13.count
#	Output	-	test-A13a.reqd

echo "UNIT Test A13a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A13.count";
echo "Output - 	Destination file from test-A13a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the data contains punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A13.count";
set Actual="test-A13a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal mahanta $TestInput > test-A13a1.output
 kocos.pl --regex test-A13.regex $TestInput > test-A13a2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A13a1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A13a2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA13a
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal mahanta ";
        cat variance1
	echo "          When Tested for --regex test-A13.regex ";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

