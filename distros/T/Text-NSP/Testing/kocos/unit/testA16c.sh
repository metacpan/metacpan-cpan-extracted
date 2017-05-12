###############################################################################

#			UNIT TEST A16c FOR kocos.pl

###############################################################################

#       Test A16c  -    Checks if the program finds correct 3rd order 
#			co-occurrences when tokens include punctuations 
#	Input	-	test-A16.count
#	Output	-	test-A16c.reqd

echo "UNIT Test A16c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A16.count";
echo "Output - 	Destination file from test-A16c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when tokens include punctuations";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A16.count";
set Actual="test-A16c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --literal on --order 3 $TestInput > test-A16c1.output
 kocos.pl --regex test-A16.regex --order 3 $TestInput > test-A16c2.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A16c1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

sort test-A16c2.output > t1
diff -w t1 t2 > variance2
#=============================================================================
#				RESULTS OF TESTA16c
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

