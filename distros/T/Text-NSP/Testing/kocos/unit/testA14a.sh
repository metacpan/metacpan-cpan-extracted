###############################################################################

#				UNIT TEST A14a FOR kocos.pl

###############################################################################

#       Test A14a  -    Checks if the program finds correct 1st order 
#			co-occurrences when target word is /\d/ and
#			data contains all weird characters
#	Input	-	test-A14.count
#	Output	-	test-A14a.reqd

echo "UNIT Test A14a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A14.count";
echo "Output - 	Destination file from test-A14a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the target words is /\d/ and data";
echo "		contains all weird symbols.";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A14.count";
set Actual="test-A14a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A14.regex $TestInput > test-A14a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A14a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA14a
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --regex test-A14.regex ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

