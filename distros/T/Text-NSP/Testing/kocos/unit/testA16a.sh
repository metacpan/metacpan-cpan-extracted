###############################################################################

#				UNIT TEST A16a FOR kocos.pl

###############################################################################

#       Test A16a  -    Checks if the program finds correct 1st order 
#			co-occurrences when tokens include punctuations 
#	Input	-	test-A16.count
#	Output	-	test-A16a.reqd

echo "UNIT Test A16a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A16.count";
echo "Output - 	Destination file from test-A16a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when tokens include punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A16.count";
set Actual="test-A16a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal on $TestInput > test-A16a1.output
 kocos.pl --regex test-A16.regex $TestInput > test-A16a2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A16a1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A16a2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA16a
#=============================================================================
if(-z variance1 && -z variance2) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --literal on ";
        cat variance1
	echo "          When Tested for --regex test-A16.regex ";
        cat variance2
endif
echo ""
/bin/rm -f t1 t2 variance1 variance2

#############################################################################

