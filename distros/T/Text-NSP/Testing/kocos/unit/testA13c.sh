###############################################################################

#			UNIT TEST A13c FOR kocos.pl

###############################################################################

#       Test A13c  -    Checks if the program finds correct 3rd order 
#			co-occurrences when data contains punctuations 
#	Input	-	test-A13.count
#	Output	-	test-A13c.reqd

echo "UNIT Test A13c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A13.count";
echo "Output - 	Destination file from test-A13c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the data contains punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A13.count";
set Actual="test-A13c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal mahanta --order 3 $TestInput > test-A13c1.output
 kocos.pl --regex test-A13.regex --order 3 $TestInput > test-A13c2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A13c1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A13c2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA13c
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

