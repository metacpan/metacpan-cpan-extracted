###############################################################################

#			INTEGRATION TEST A3 FOR statistic.pl and kocos.pl

###############################################################################

#       Test A3  -     	Checks for the compatibility between the programs
#			statistic and kocos
#	Input	-	
#	To count-	test-A3.in
#	To statistic 	test-A3.count
#	To kocos -	test-A3.out
#	Output	-	test-A3[a-d].reqd

echo "Integrated Test A3 -";
echo "	 	For NSP program statistic.pl and kocos.pl";
echo "Input - 	";
echo "To count -	Source file from test-A3.in";
echo "To statistic -	test-A3.count";
echo "To kocos -	test-A3.out";
echo "Output - 	Destination file from test-A3[a-d].reqd";
echo "Test -   	Checks for the compatibility between the programs"; 
echo "		statistic.pl and kocos.pl for different orders";

#=============================================================================
#				INPUT
#=============================================================================

set TestInput="test-A3.in";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

echo "running count.pl";
count.pl --newLine test-A3.count $TestInput 
echo "running statistic.pl";
statistic.pl ll test-A3.out test-A3.count
echo "running kocos with order = 1";
kocos.pl --literal line test-A3.out > test-A3a.output
echo "running kocos with order = 2";
kocos.pl --literal line --order 2 test-A3.out > test-A3b.output
echo "running kocos with order = 3";
kocos.pl --literal line --order 3 test-A3.out > test-A3c.output
echo "running kocos with order = 4";
kocos.pl --literal line --order 4 test-A3.out > test-A3d.output

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================

sort test-A3a.output > t1
sort test-A3a.reqd > t2
diff -w t1 t2 > variance1

sort test-A3b.output > t3
sort test-A3b.reqd > t4
diff -w t4 t3 > variance2

sort test-A3c.output > t5
sort test-A3c.reqd > t6
diff -w t5 t6 > variance3

sort test-A3d.output > t7
sort test-A3d.reqd > t8
diff -w t7 t8 > variance4

#=============================================================================
#				RESULTS OF TESTA3
#=============================================================================
if(-z variance1 && -z variance2 && -z variance3 && -z variance4) then
        echo "STATUS : OK Test Results Match.....";
else
	echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against test-A3a.reqd - ";
        cat variance1
	echo "When Tested Against KEY file test-A3b.reqd - ";
        cat variance2
	echo "When Tested Against KEY file test-A3c.reqd - ";
        cat variance3
	echo "When Tested Against KEY file test-A3d.reqd - ";
        cat variance4

endif
echo ""
/bin/rm -f t1 t2 variance1 t3 t4 variance2 filename t5 variance3 variance4 t6 t7 t8 test-A3.out test-A3.count

#############################################################################

