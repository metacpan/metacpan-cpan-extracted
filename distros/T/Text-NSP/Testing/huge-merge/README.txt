*******************************************************************************

		     README.txt FOR Testing huge-merge.pl

                               Version 0.01
                         Copyright (C) 2009-2010
                       Ted Pedersen, tpederse@umn.edu
                       University of Minnesota, Duluth
                         Ying Liu liux0395@umn.edu
                    University of Minnesota, Twin Cities 

		   http://www.d.umn.edu/~tpederse/nsp.html

*******************************************************************************


Testing for huge-merge.pl
------------------------------

Ying Liu
liux0395@umn.edu
02/20/2010

1. Introduction: 
----------------

This program is a component of the N-gram Statistics Package that combines
two bigram count files.
The scripts and files provided here could be used to test the correct 
behavior of the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test huge-merge.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Test A1:	Tests on two general bigram files

Test A2:	Tests on three general bigram files

Test A3:	Tests when the two count files share all bigrams



2.2 Error conditions:
----------------------

Tests written in testB*.sh test huge-merge.pl under error conditions.
Run error-op.sh to run all test cases testB*.sh

Test B1:	Tests when a bigram is repeated in the same file

Test B2:	Tests when a bigram file is not sorted correctly 

3. Conclusions:
---------------

We have tested program huge-combine.pl enough to conclude that it runs 
correctly. We have also provided the test scripts so that future versions of 
huge-combine.pl can be compared to the current version against these scripts.
