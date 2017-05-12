*******************************************************************************

		     README.txt FOR Testing sval2plain.pl

                               Version 0.01
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for sval2plain.pl
--------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
06/02/2004


1. Introduction:
----------------

This program is a component of the SenseClusters package that converts a 
given file in Senseval-2 format into plain text format. The scripts and 
files provided here could be used to test the correct behaviour of the 
program and backward compatibility. 

2. Tests:
---------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test sval2plain.pl under normal conditions.

Test A1  :	Tests sval2plain on a Senseval-2 word art.n

Test A2  :	Tests on mixed data containing two target words

Test A3  :	Tests when sval2 file contains sat tags


2.2 Error conditions:
----------------------

Tests written in testB*.sh test sval2plain.pl under error conditions.

Test B1  :	Tests when input file has no context tags

3. Conclusions:
---------------

We have tested program sval2plain.pl enough to conclude that it runs correctly.
We have provided the test scripts so that future versions of sval2plain.pl 
can be compared to the current version against these scripts.

