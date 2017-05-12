###############################################################################

#				UNIT TEST A13d FOR kocos.pl

###############################################################################

#       Test A13d  -    Checks if the program finds correct 4th order 
#			co-occurrences when data contains punctuations 
#	Input	-	test-A13.count
#	Output	-	test-A13d.reqd

echo "UNIT Test A13d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A13.count";
echo "Output - 	Destination file from test-A13d.reqd";
echo "Test -    	Checks if the program finds correct 4th order";
echo "		co-occurrences when the data contains punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A13.count";
set Actual="test-A13d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal mahanta --order 4 $TestInput > test-A13d1.output
 kocos.pl --regex test-A13.regex --order 4 $TestInput > test-A13d2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A13d1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A13d2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA13d
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal mahanta ";
        cat variance1
	echo "		When Tested for --regex test-A13.regex";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

