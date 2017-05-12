###############################################################################

#				UNIT TEST A14d FOR kocos.pl

###############################################################################

#       Test A14d  -    Checks if the program finds correct 4th order 
#			co-occurrences when target word is /\d/ and
#			data contains some weird characters
#	Input	-	test-A14.count
#	Output	-	test-A14d.reqd

echo "UNIT Test A14d -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A14.count";
echo "Output - 	Destination file from test-A14d.reqd";
echo "Test -    	Checks if the program finds correct 4th order";
echo "		co-occurrences when the target word is /\d/ and data";
echo "		contains some weird characters.";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A14.count";
set Actual="test-A14d.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A14.regex --order 4 $TestInput > test-A14d.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A14d.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA14d
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "		When Tested for --regex test-A14.regex";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

