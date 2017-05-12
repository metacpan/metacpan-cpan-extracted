###############################################################################

#				UNIT TEST A14b FOR kocos.pl

###############################################################################

#       Test A14b  -    Checks if the program finds correct 2nd order 
#			co-occurrences when target is /\d/ and data 
#			contains all weird characters
#	Input	-	test-A14.count
#	Output	-	test-A14b.reqd

echo "UNIT Test A14b -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A14.count";
echo "Output - 	Destination file from test-A14b.reqd";
echo "Test -    	Checks if the program finds correct 2nd order";
echo "		co-occurrences when target is /\d/ and data contains";
echo "		all weird characters";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A14.count";
set Actual="test-A14b.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A14.regex --order 2 $TestInput > test-A14b.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A14b.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA14b
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

