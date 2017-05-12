###############################################################################

#				UNIT TEST A16b FOR kocos.pl

###############################################################################

#       Test A16b  -    Checks if the program finds correct 2nd order 
#			co-occurrences when tokens include punctuations 
#	Input	-	test-A16.count
#	Output	-	test-A16b.reqd

echo "UNIT Test A16b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A16.count";
echo "Output - 	Destination file from test-A16b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when tokens include punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A16.count";
set Actual="test-A16b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal on --order 2 $TestInput > test-A16b1.output
 kocos.pl --regex test-A16.regex --order 2 $TestInput > test-A16b2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A16b1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A16b2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA16b
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

