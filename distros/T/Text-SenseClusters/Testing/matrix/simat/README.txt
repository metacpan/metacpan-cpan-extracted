*******************************************************************************

		     README.txt FOR Testing simat.pl

                               Version 0.06
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth


*******************************************************************************


Testing for simat.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
02/11/2004


1. Introduction: 
----------------

This program is a component of a SenseClusters package that constructs 
a similarity matrix from given context vectors. The scripts and files 
provided here could be used to test the correct behaviour of the program 
and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test simat.pl under normal conditions.

Test A1:	 Tests simat on general vectors  

Test A2:	 Tests simat when cosine between all vector pairs is 1 

Test A3:	 Tests simat when cosine between 2 integer vectors is 0

Test A4:	 Tests simat when cosine between all vector pairs is 0

Test A5:	 Tests simat when vectors contain real numbers and
		 cosine between any 2 pairs is 0

Test A6:	 Tests simat on vectors of real numbers

Test A7:	 Tests simat on a square vector matrix

Test A8:	 Tests simat on a symmetric matrix

Test A9:	 Tests simat on binary vectors 

Test A10:	 Tests simat on both dense and sparse, real vectors

Test A11:	 Tests simat on both dense and sparse, int vectors


2.2 Error conditions:
----------------------

Tests written in testB*.sh test simat.pl under error conditions.

Test B1:	 Tests simat when the 1st line in vector file is wrong

Test B2:	 Tests simat when the column indices are wrong

Test B3:	 Tests simat when vector file doesn't contain
		 specified number of rows

3. Conclusions:
---------------

We have tested program simat.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
simat.pl can be compared to the current version against these scripts.

