###############################################################################

#				UNIT TEST A3 FOR keyconvert.pl

###############################################################################

#       Test A3  -      Tests program keyconvert.pl on sample keyfiles
#	Input	-	test-A3.keyin
#	Output	-	test-A3.keyout

echo "UNIT Test A3 -";
echo "		For Key Convertor keyconvert.pl";
echo "Input - 	Senseval2 Key file from test-A3.keyin";
echo "Output - 	Equivalent SenseClusters Key file from test-A3.keyout";
echo "Test -    	Tests program keyconvert.pl when --attach_P option is selected";


#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A3.keyin";
set Actual="test-A3.keyout";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 keyconvert.pl --attach_P $TestInput test-A3.output


#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================
sort test-A3.output > t1
sort $Actual > t2
diff -w t1 t2 > variance

#=============================================================================
#				RESULTS OF TESTA3
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		When Tested Against $Actual - ";
        cat variance
endif
echo ""
/bin/rm -f t1 t2 variance test-A3.output 

#############################################################################

