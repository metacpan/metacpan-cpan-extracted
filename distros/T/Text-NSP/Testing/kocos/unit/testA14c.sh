###############################################################################

#			UNIT TEST A14c FOR kocos.pl

###############################################################################

#       Test A14c  -    Checks if the program finds correct 3rd order 
#			co-occurrences when target word is /\d/ and 
#			data contains some weird characters
#	Input	-	test-A14.count
#	Output	-	test-A14c.reqd

echo "UNIT Test A14c -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A14.count";
echo "Output - 	Destination file from test-A14c.reqd";
echo "Test -    	Checks if the program finds correct 3rd order";
echo "		co-occurrences when the target word is /\d/ and";
echo "		data contains some weird characters";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A14.count";
set Actual="test-A14c.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A14.regex --order 3 $TestInput > test-A14c.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A14c.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA14c
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
	echo "          When Tested for --regex test-A14.regex ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

