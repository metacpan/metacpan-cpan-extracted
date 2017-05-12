###############################################################################

#			INTEGRATION TEST A1 FOR count.pl and kocos.pl

###############################################################################

#       Test A1  -     	Checks for the compatibility between the programs
#			count and kocos
#	Input	-	
#	To count-	test-A1.in
#	To kocos -	test-A1.out
#	Output	-	test-A1[a-d].reqd

echo "Integrated Test A1 -";
echo "	 	For NSP program count.pl and kocos.pl";
echo "Input - 	";
echo "To count -	Source file from test-A1.in";
echo "To kocos -	test-A1.out";
echo "Output - 	Destination file from test-A1[a-d].reqd";
echo "Test -   	Checks for the compatibility between the programs"; 
echo "		count.pl and kocos.pl for different orders";

#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A1.in";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

echo "running count.pl";
count.pl --newLine test-A1.out $TestInput 
echo "running kocos with order = 1";
kocos.pl --literal line test-A1.out > test-A1a.output
echo "running kocos with order = 2";
kocos.pl --literal line --order 2 test-A1.out > test-A1b.output
echo "running kocos with order = 3";
kocos.pl --literal line --order 3 test-A1.out > test-A1c.output
echo "running kocos with order = 4";
kocos.pl --literal line --order 4 test-A1.out > test-A1d.output

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================

sort test-A1a.output > t1
sort test-A1a.reqd > t2
diff -w t1 t2 > variance1

sort test-A1b.output > t3
sort test-A1b.reqd > t4
diff -w t4 t3 > variance2

sort test-A1c.output > t5
sort test-A1c.reqd > t6
diff -w t5 t6 > variance3

sort test-A1d.output > t7
sort test-A1d.reqd > t8
diff -w t7 t8 > variance4


#=============================================================================
#				RESULTS OF TESTA1
#=============================================================================
if(-z variance1 && -z variance2 && -z variance3 && -z variance4) then
        echo "STATUS : OK Test Results Match.....";
else
	echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against test-A1a.reqd - ";
        cat variance1
	echo "When Tested Against KEY file test-A1b.reqd - ";
        cat variance2
	echo "When Tested Against KEY file test-A1c.reqd - ";
        cat variance3
	echo "When Tested Against KEY file test-A1d.reqd - ";
        cat variance4


endif
echo ""
/bin/rm -f t1 t2 variance1 t3 t4 variance2 filename t5 variance3 variance4 t6 t7 t8 test-A1.out

#############################################################################

