*******************************************************************************

		     README.txt FOR Testing find-compounds.pl

                               Version 0.01
                         Copyright (C) 2010
                       Ted Pedersen, tpederse@umn.edu
                       University of Minnesota, Duluth
						Ying Liu, liux0395@umn.edu
                   University of Minnesota, Twin Cities 

		   http://www.d.umn.edu/~tpederse/nsp.html

*******************************************************************************


Testing for find-compounds.pl
------------------------------

Ying Liu
liux0395@umn.edu
11/01/2010

1. Introduction: 
----------------

This program is a component of the bigram Statistics Package that sort 
one bigram count file.
The scripts and files provided here could be used to test the correct 
behavior of the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test huge-count.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Test A1:	Tests on general English file 
Test A2: 	Tests on general english file without compounds words

3. Conclusions:
---------------

We have tested program find-compounds.pl enough to conclude that it runs 
correctly. We have also provided the test scripts so that future versions of 
find-compounds.pl can be compared to the current version against these scripts.
