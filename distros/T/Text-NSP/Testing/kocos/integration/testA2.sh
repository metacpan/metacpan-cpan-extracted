###############################################################################

#			INTEGRATION TEST A2 FOR count.pl and kocos.pl

###############################################################################

#       Test A2  -     	Checks for the compatibility between the programs
#			count and kocos
#	Input	-	
#	To count-	test-A2.in
#	To kocos -	test-A2.out
#	Output	-	test-A2[a-d].reqd

echo "Integrated Test A2 -";
echo "	 	For NSP program count.pl and kocos.pl";
echo "Input - 	";
echo "To count -	Source file from test-A2.in";
echo "To kocos -	test-A2.out";
echo "Output - 	Destination file from test-A2[a-d].reqd";
echo "Test -   	Checks for the compatibility between the programs"; 
echo "		count.pl and kocos.pl for different orders";

#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A2.in";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

echo "running count.pl";
count.pl --newLine test-A2.out $TestInput 
echo "running kocos with order = 1";
kocos.pl --literal line test-A2.out > test-A2a.output
echo "running kocos with order = 2";
kocos.pl --literal line --order 2 test-A2.out > test-A2b.output
echo "running kocos with order = 3";
kocos.pl --literal line --order 3 test-A2.out > test-A2c.output
echo "running kocos with order = 4";
kocos.pl --literal line --order 4 test-A2.out > test-A2d.output

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================

sort test-A2a.output > t1
sort test-A2a.reqd > t2
diff -w t1 t2 > variance1

sort test-A2b.output > t3
sort test-A2b.reqd > t4
diff -w t4 t3 > variance2

sort test-A2c.output > t5
sort test-A2c.reqd > t6
diff -w t5 t6 > variance3

sort test-A2d.output > t7
sort test-A2d.reqd > t8
diff -w t7 t8 > variance4


#=============================================================================
#				RESULTS OF TESTA2
#=============================================================================
if(-z variance1 && -z variance2 && -z variance3 && -z variance4) then
        echo "STATUS : OK Test Results Match.....";
else
	echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against test-A2a.reqd - ";
        cat variance1
	echo "When Tested Against KEY file test-A2b.reqd - ";
        cat variance2
	echo "When Tested Against KEY file test-A2c.reqd - ";
        cat variance3
	echo "When Tested Against KEY file test-A2d.reqd - ";
        cat variance4


endif
echo ""
/bin/rm -f t1 t2 variance1 t3 t4 variance2 filename t5 variance3 variance4 t6 t7 t8 test-A2.out

#############################################################################

