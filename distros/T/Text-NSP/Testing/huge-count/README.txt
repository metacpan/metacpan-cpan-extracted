*******************************************************************************

		     README.txt FOR Testing huge-count.pl

                               Version 0.03
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare pura0010@d.umn.edu
                       University of Minnesota, Duluth
                        Ying Liu, liux0395@umn.edu
                   University of Minnesota, Twin Cities 

		   http://www.d.umn.edu/~tpederse/nsp.html

*******************************************************************************


Testing for huge-count.pl
---------------------------

Ying Liu
liux0395@umn.edu
02/13/2010

1. Introduction: 
----------------

This program is a component of the N-gram Statistics Package that efficiently
runs count.pl on a large data. 
The scripts and files provided here could be used to test the correct 
behaviour of the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test huge-count.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Test A1:	Tests huge-count when input is a single data file

Test A2:	Tests huge-count when input is a directory

Test A3:	Tests huge-count when input is a list of plain files

Test A4:	Tests huge-count's --frequency option

Test A5:	Runs huge-count with --token, --nontoken, --newLine, --window 
		options together

Test A6:	Tests huge-count's --remove option

Test A7:	Runs A1, A2, A3 without --newLine

Test A9: 	Runs A2 with --tokenline & --split option	

Test A10: 	Runs A2 with --tokenline --split --remove --uremove  option

Test A11: 	Runs A2 with --tokenline --remove --uremove  option

Test A12: 	Runs A2 with --tokenline --frequency --ufrequency option


2.2 Error conditions:
----------------------

Tests written in testB*.sh test huge-count.pl under error conditions.
Run error-op.sh to run all test cases testB*.sh

Test B1:	Tests huge-count when input contains more than one directory


3. Conclusions:
---------------

We have tested program huge-count.pl enough to conclude that it runs 
correctly. We have also provided the test scripts so that future versions of 
huge-count.pl can be compared to the current version against these scripts.

