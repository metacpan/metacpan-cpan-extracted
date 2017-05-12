*******************************************************************************

		     README.txt FOR Testing svdpackoutpl

                               Version 0.01
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for svdpackout.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
09/21/2003


1. Introduction: 
----------------

This program is a component of a SenseClusters package that reconstructs 
a matrix from its singular values and vectors created by SVDPack. 
The scripts and files provided here could be used to test the correct 
behaviour of the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test svdpackout.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Test A1 :	Tests reconstruction when k=#columns
		on cases:
		A1a: sqaure int m = n
		A1b: square real m = n
		A1c: symmetric int
		A1d: symmetric real
		A1e: rectangular int m > n
		A1f: rectangular real m > n
		A1g: rectangular int m < n
		A1h: rectangular real m < n
			
Test A2 :	Tests when all rows are linear combinations of the 0th row 

Test A3 :	Tests reconstruction when k < #columns on cases :
		A3a: m = n int 
		A3b: m=n real
		A3c: m > n int
		A3d: m > n real
		A3e: m < n int
		A3f: m < n real 

Test A4 :	Tests svdpackout on Landauer's illustration matrix from 
		LSA paper 

Test A5 :	Tests svdpackout's rowonly construction

2.2 Error conditions:
----------------------

Tests written in testB*.sh form test svdpackout.pl under error conditions.

Test B1 :	lao2 file doesn't have pre-specified #S-values

Test B2 :	lav2 and lao2 files are interchanged

3. Conclusions:
---------------

We have tested program svdpackout.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
svdpackout.pl can be compared to the current version against these scripts.

