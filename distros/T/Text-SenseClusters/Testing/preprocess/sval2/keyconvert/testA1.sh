###############################################################################

#				UNIT TEST A1 FOR keyconvert.pl

###############################################################################

#       Test A1  -      Tests program keyconvert.pl on sample keyfiles
#	Input	-	test-A1.keyin
#	Output	-	test-A1.keyout

echo "UNIT Test A1 -";
echo "		For Key Convertor keyconvert.pl";
echo "Input - 	Senseval2 Key file from test-A1.keyin";
echo "Output - 	Equivalent SenseClusters Key file from test-A1.keyout";
echo "Test -    	Tests program keyconvert.pl on sample keyfiles";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A1.keyin";
set Actual="test-A1.keyout";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 keyconvert.pl $TestInput test-A1.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A1.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA1
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against $Actual - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A1.output 

#############################################################################

