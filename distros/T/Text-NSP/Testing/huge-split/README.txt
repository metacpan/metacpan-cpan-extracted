*******************************************************************************

		     README.txt FOR Testing huge-split.pl

                               Version 0.01
                         Copyright (C) 2009-2010
                       Ted Pedersen, tpederse@umn.edu
                       University of Minnesota, Duluth
                         Ying Liu liux0395@umn.edu
                    University of Minnesota, Twin Cities 

		   http://www.d.umn.edu/~tpederse/nsp.html

*******************************************************************************


Testing for huge-split.pl
------------------------------

Ying Liu
liux0395@umn.edu
04/02/2010

1. Introduction: 
----------------

This program is a component of the N-gram Statistics Package that removes 
bigrams with low/high frequencies. 
The scripts and files provided here could be used to test the correct 
behavior of the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test huge-combine.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Test A1:	Tests on --split

2.2 Error conditions:
----------------------

Tests written in testB*.sh test huge-combine.pl under error conditions.
Run error-op.sh to run all test cases testB*.sh

Test B1:	Tests without --split option 


3. Conclusions:
---------------

We have tested program huge-delete.pl enough to conclude that it runs 
correctly. We have also provided the test scripts so that future versions of 
huge-delete.pl can be compared to the current version against these scripts.
