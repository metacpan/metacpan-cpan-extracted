###############################################################################

#			UNIT TEST A2 FOR keyconvert.pl

###############################################################################

#       Test A2 -       Tests program keyconvert.pl on actual Senseval2 keyfile
#	Input	-	fine.key	
#	Output	-	SenseCluster.key

echo "UNIT Test A2 -";
echo "		For Key Convertor keyconvert.pl";
echo "Input - 	Senseval2 Key file from fine.key";
echo "Output - 	Equivalent SenseClusters Key file from SenseCluster.key";
echo "Test -    	Tests program keyconvert.pl on actual Senseval keyfile.";

#=============================================================================
#				RUN THE PROGRAM
#=============================================================================

 keyconvert.pl fine.key SenseCluster.key

#=============================================================================
#				SORT THE RESULTS AND COMPARE
#=============================================================================

wc -l fine.key > lines1
wc -l SenseCluster.key > lines2

perl -pi.orig -e 's/[^\d]//g' lines1
perl -pi.orig -e 's/[^\d]//g' lines2
diff -w lines1 lines2 > variance

#=============================================================================
#				RESULTS OF TESTA2
#=============================================================================
if(-z variance) then
        echo "STATUS : 	OK Test Results Match.....";
else
	echo "STATUS : 	ERROR Test Results don't Match....";
        echo "		Difference found in number of lines against fine.key";
        cat variance
endif
echo ""
/bin/rm -f lines1 lines2 variance SenseCluster.key 
/bin/rm *.orig

#############################################################################

