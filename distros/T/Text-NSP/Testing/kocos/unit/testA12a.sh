###############################################################################

#				UNIT TEST A12a FOR kocos.pl

###############################################################################

#       Test A12a  -    Checks if the program finds correct 1st order 
#			co-occurrences when target word is /nA$/ in
#			Hindi transliterated text 
#	Input	-	test-A12.count
#	Output	-	test-A12a.reqd

echo "UNIT Test A12a -";
echo "		For kth order co-occurrence program kocos.pl";
echo "Input - 	Source file from test-A12.count";
echo "Output - 	Destination file from test-A12a.reqd";
echo "Test -    	Checks if the program finds correct 1st order";
echo "		co-occurrences when the target words end in 'nA' in";
echo "		Hindi transliterated text";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A12.count";
set Actual="test-A12a.reqd";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 kocos.pl --regex test-A12.regex $TestInput > test-A12a.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A12a.output > t1
sort $Actual > t2
diff -w t1 t2 > variance1

#=============================================================================
#				RESULTS OF TESTA12a
#=============================================================================
if(-z variance1) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested for --regex test-A12.regex ";
        cat variance1
endif
echo ""
/bin/rm -f t1 t2 variance1 

#############################################################################

