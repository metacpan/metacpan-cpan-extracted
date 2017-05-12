###############################################################################

#				UNIT TEST A16d FOR kocos.pl

###############################################################################

#       Test A16d  -    Checks if the program finds correct 4th order 
#			co-occurrences when tokens include punctuations 
#	Input	-	test-A16.count
#	Output	-	test-A16d.reqd

echo "UNIT Test A16d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A16.count";
echo "Output - 	Destination file from test-A16d.reqd";
echo "Test -    	Checks if the program finds correct 4th order";
echo "		co-occurrences when tokens include punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A16.count";
set Actual="test-A16d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal on --order 4 $TestInput > test-A16d1.output
 kocos.pl --regex test-A16.regex --order 4 $TestInput > test-A16d2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A16d1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A16d2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA16d
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

